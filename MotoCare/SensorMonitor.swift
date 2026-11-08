//
//  SensorMonitor.swift
//  MotoCare
//
//  Lee los sensores de movimiento (acelerómetro + giroscopio, vía Core Motion)
//  durante el modo viaje: publica valores en vivo y picos para la pantalla, y
//  pasa cada muestra al RideRecorder para grabar el viaje en CSV (MVP paso 2).
//  Con estos datos reales fijaremos los umbrales del detector de accidentes.
//
//  No necesita permiso del usuario: a diferencia del GPS, el acelerómetro y el
//  giroscopio no están protegidos por privacidad en iOS.
//

import Foundation
import Combine
import CoreMotion

final class SensorMonitor: ObservableObject {

    /// 100 Hz: suficiente para captar un impacto, que dura decenas de milisegundos.
    static let sampleRateHz: Double = 100
    /// La pantalla se refresca cada 10 muestras (10 veces por segundo), no a 100 Hz.
    private static let samplesPerUIUpdate = 10
    /// El CSV se escribe en lotes de 100 muestras (más o menos una vez por segundo).
    private static let samplesPerFlush = 100
    private static let degreesPerRadian = 180 / Double.pi

    /// false en el simulador, que no tiene sensores de movimiento.
    let isAvailable: Bool

    // MARK: Valores en vivo (aceleración y giro: máximo de la última décima de segundo)
    @Published private(set) var accelerationG: Double = 0
    @Published private(set) var rotationDegPerSec: Double = 0
    @Published private(set) var rollDeg: Double = 0
    @Published private(set) var pitchDeg: Double = 0

    // MARK: Resumen del viaje
    @Published private(set) var peakAccelerationG: Double = 0
    @Published private(set) var peakRotationDegPerSec: Double = 0
    @Published private(set) var sampleCount = 0
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var markerCount = 0
    @Published private(set) var isRunning = false

    /// Última velocidad del GPS en km/h (la actualiza RideSessionManager); va en cada fila del CSV.
    var latestSpeedKmh: Double = 0

    private let motionManager = CMMotionManager()
    private var recorder: RideRecorder?
    private var pendingLines: [String] = []
    private var firstTimestamp: TimeInterval?
    private var samples = 0
    private var lastElapsed: TimeInterval = 0
    private var windowMaxAcc = 0.0
    private var windowMaxRot = 0.0
    private var lastRoll = 0.0
    private var lastPitch = 0.0
    private var peakAcc = 0.0
    private var peakRot = 0.0
    /// Marcador pendiente de escribir en la siguiente fila (0 = ninguno).
    private var pendingMarker = 0

    init() {
        isAvailable = motionManager.isDeviceMotionAvailable
    }

    /// Empieza a leer los sensores. Si `recorder` no es nil, cada muestra se graba en el CSV.
    func start(recorder: RideRecorder?) {
        guard isAvailable, !isRunning else { return }
        resetForNewRide()
        self.recorder = recorder
        isRunning = true

        motionManager.deviceMotionUpdateInterval = 1 / Self.sampleRateHz
        // Las lecturas llegan en la cola principal; assumeIsolated se lo confirma al
        // compilador, porque el proyecto aísla todo en el MainActor por defecto.
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            MainActor.assumeIsolated {
                self.ingest(motion)
            }
        }
    }

    /// Para los sensores y vuelca al CSV las muestras que queden pendientes.
    func stop() {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false
        flushToRecorder()
        publish()
        recorder = nil
    }

    /// Etiqueta la siguiente muestra con un número de evento (pruebas controladas).
    func addMarker() {
        guard isRunning else { return }
        markerCount += 1
        pendingMarker = markerCount
    }

    // MARK: - Privado

    private func resetForNewRide() {
        pendingLines.removeAll(keepingCapacity: true)
        firstTimestamp = nil
        samples = 0
        lastElapsed = 0
        windowMaxAcc = 0
        windowMaxRot = 0
        lastRoll = 0
        lastPitch = 0
        peakAcc = 0
        peakRot = 0
        pendingMarker = 0
        latestSpeedKmh = 0
        markerCount = 0
        publish()
    }

    private func ingest(_ motion: CMDeviceMotion) {
        // Tras stop() aún pueden llegar lecturas que ya estaban en cola: se ignoran.
        guard isRunning else { return }

        let start = firstTimestamp ?? motion.timestamp
        firstTimestamp = start
        let t = motion.timestamp - start

        let a = motion.userAcceleration      // g, sin la gravedad
        let g = motion.gravity               // g
        let r = motion.rotationRate          // rad/s
        let attitude = motion.attitude       // rad
        let accMag = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
        let rotMag = (r.x * r.x + r.y * r.y + r.z * r.z).squareRoot()

        samples += 1
        lastElapsed = t
        windowMaxAcc = max(windowMaxAcc, accMag)
        windowMaxRot = max(windowMaxRot, rotMag)
        peakAcc = max(peakAcc, accMag)
        peakRot = max(peakRot, rotMag)
        lastRoll = attitude.roll * Self.degreesPerRadian
        lastPitch = attitude.pitch * Self.degreesPerRadian

        if recorder != nil {
            // String(format:) usa siempre punto decimal; formatted() usaría la coma
            // del español y rompería el CSV.
            pendingLines.append(String(
                format: "%.3f,%.1f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.2f,%.2f,%.2f,%ld",
                t, latestSpeedKmh,
                a.x, a.y, a.z, accMag,
                g.x, g.y, g.z,
                r.x, r.y, r.z, rotMag,
                lastRoll, lastPitch, attitude.yaw * Self.degreesPerRadian,
                pendingMarker))
            pendingMarker = 0
            if pendingLines.count >= Self.samplesPerFlush { flushToRecorder() }
        }

        if samples % Self.samplesPerUIUpdate == 0 { publish() }
    }

    private func flushToRecorder() {
        guard !pendingLines.isEmpty else { return }
        recorder?.append(pendingLines)
        pendingLines.removeAll(keepingCapacity: true)
    }

    /// Copia los valores internos a las propiedades @Published (refresca la pantalla).
    private func publish() {
        accelerationG = windowMaxAcc
        rotationDegPerSec = windowMaxRot * Self.degreesPerRadian
        rollDeg = lastRoll
        pitchDeg = lastPitch
        peakAccelerationG = peakAcc
        peakRotationDegPerSec = peakRot * Self.degreesPerRadian
        sampleCount = samples
        elapsedSeconds = lastElapsed
        windowMaxAcc = 0
        windowMaxRot = 0
    }
}
