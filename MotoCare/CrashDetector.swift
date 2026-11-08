//
//  CrashDetector.swift
//  MotoCare
//
//  Detector de accidentes (MVP paso 3). Lógica PURA: no usa Core Motion, GPS ni
//  interfaz. Recibe muestras (tiempo, velocidad, aceleración, giro) y decide.
//  Así la misma lógica corre en la app en tiempo real y en el Mac sobre viajes
//  grabados (Tools/DetectorReplay), para afinar los umbrales sin volver a rodar.
//
//  Posible accidente = ibas rápido + impacto o volteo + te detienes.
//  Si además te quedas quieto (como alguien inconsciente), la confianza es alta.
//
//  Umbrales iniciales sacados de las pruebas en casa (8-nov-2026): manejar el
//  móvil da 1–4 g y 300–600 °/s; dejarlo caer en la cama desde ~1 m, 14–30 g y
//  ~2.000–2.900 °/s. Se afinarán con viajes reales en coche y en moto.
//

import Foundation

struct CrashDetector {

    struct Config {
        /// Velocidad mínima alcanzada antes del impacto. Descarta caídas del móvil en casa o andando.
        var minSpeedBeforeKmh = 20.0
        /// Cuántos segundos hacia atrás se busca esa velocidad previa.
        var speedLookbackSeconds = 15.0
        /// Impacto: aceleración (sin gravedad) a partir de la cual se considera un golpe.
        var impactAccelerationG = 6.0
        /// Volteo: giro a partir del cual se considera que el cuerpo da vueltas.
        var tumbleRotationDegPerSec = 1000.0
        /// Segundos tras el impacto en los que se recogen los picos del golpe.
        var impactWindowSeconds = 2.0
        /// Margen para que pase el propio golpe (rebotes) antes de medir la quietud.
        var settleSeconds = 1.5
        /// Por debajo de esta velocidad se considera que te has detenido...
        var stoppedSpeedKmh = 5.0
        /// ...y este es el plazo para detenerte tras el impacto. Si no, se descarta (un bache, una frenada).
        var stopTimeoutSeconds = 15.0
        /// Si mientras se observa vuelves a superar esta velocidad, el viaje sigue: se descarta.
        var resumedSpeedKmh = 10.0
        /// Duración de la observación de quietud tras detenerse.
        var stillnessWindowSeconds = 10.0
        /// Una muestra cuenta como "quieta" por debajo de estos dos valores.
        var stillAccelerationG = 0.15
        var stillRotationDegPerSec = 30.0
        /// Proporción de muestras quietas necesaria para dar confianza alta.
        var stillFractionForHighConfidence = 0.8
        /// Modo prueba en casa: ignora las condiciones de velocidad para poder probar sin moto.
        var ignoreSpeed = false
    }

    enum Phase: Int {
        case monitoring = 0   // vigilando
        case impact = 1       // impacto: esperando a ver si te detienes
        case observing = 2    // detenido: observando si te quedas quieto
        case detected = 3     // posible accidente: esperando respuesta del motero
    }

    enum Confidence: String {
        case medium   // impacto + parada
        case high     // impacto + parada + quietud
    }

    struct Detection: Identifiable {
        let id = UUID()
        let impactTime: Double
        let detectedTime: Double
        let peakAccelerationG: Double
        let peakRotationDegPerSec: Double
        let speedBeforeKmh: Double
        /// Proporción de la ventana de observación en la que estuvo quieto (0…1).
        let stillFraction: Double
        let confidence: Confidence
    }

    var config: Config
    private(set) var phase: Phase = .monitoring

    private var speedHistory: [(t: Double, kmh: Double)] = []
    private var impactTime = 0.0
    private var peakAcceleration = 0.0
    private var peakRotation = 0.0
    private var speedBefore = 0.0
    private var observeStart = 0.0
    private var observedSamples = 0
    private var stillSamples = 0

    init(config: Config = Config()) {
        self.config = config
    }

    /// Procesa una muestra. Devuelve la detección solo en el instante en que se confirma.
    mutating func process(t: Double, speedKmh: Double, accelerationG: Double, rotationDegPerSec: Double) -> Detection? {
        recordSpeed(t: t, kmh: speedKmh)

        switch phase {
        case .monitoring:
            guard accelerationG >= config.impactAccelerationG
                    || rotationDegPerSec >= config.tumbleRotationDegPerSec else { return nil }
            let before = maxSpeed(since: t - config.speedLookbackSeconds)
            guard config.ignoreSpeed || before >= config.minSpeedBeforeKmh else { return nil }
            phase = .impact
            impactTime = t
            peakAcceleration = accelerationG
            peakRotation = rotationDegPerSec
            speedBefore = before
            return nil

        case .impact:
            if t - impactTime <= config.impactWindowSeconds {
                peakAcceleration = max(peakAcceleration, accelerationG)
                peakRotation = max(peakRotation, rotationDegPerSec)
            }
            let stopped = config.ignoreSpeed || speedKmh <= config.stoppedSpeedKmh
            if stopped && t - impactTime >= config.settleSeconds {
                phase = .observing
                observeStart = t
                observedSamples = 0
                stillSamples = 0
            } else if t - impactTime > config.stopTimeoutSeconds {
                phase = .monitoring   // no se detuvo: seguramente un bache o una frenada fuerte
            }
            return nil

        case .observing:
            if !config.ignoreSpeed && speedKmh >= config.resumedSpeedKmh {
                phase = .monitoring   // ha vuelto a circular
                return nil
            }
            observedSamples += 1
            if accelerationG < config.stillAccelerationG && rotationDegPerSec < config.stillRotationDegPerSec {
                stillSamples += 1
            }
            guard t - observeStart >= config.stillnessWindowSeconds else { return nil }

            let stillFraction = Double(stillSamples) / Double(max(observedSamples, 1))
            phase = .detected
            return Detection(
                impactTime: impactTime,
                detectedTime: t,
                peakAccelerationG: peakAcceleration,
                peakRotationDegPerSec: peakRotation,
                speedBeforeKmh: speedBefore,
                stillFraction: stillFraction,
                confidence: stillFraction >= config.stillFractionForHighConfidence ? .high : .medium)

        case .detected:
            return nil   // hasta que el motero responda (acknowledge)
        }
    }

    /// El motero ha respondido ("Estoy bien"): se vuelve a vigilar.
    mutating func acknowledge() {
        phase = .monitoring
    }

    /// Nuevo viaje: se borra el estado pero se conserva la configuración.
    mutating func reset() {
        phase = .monitoring
        speedHistory.removeAll()
    }

    // MARK: - Velocidad previa

    /// Guarda la velocidad como mucho cada medio segundo (o cuando cambia): ~30 entradas en 15 s.
    private mutating func recordSpeed(t: Double, kmh: Double) {
        if let last = speedHistory.last, t - last.t < 0.5, last.kmh == kmh { return }
        speedHistory.append((t: t, kmh: kmh))
        let oldest = t - config.speedLookbackSeconds - 1
        if let first = speedHistory.first, first.t < oldest {
            speedHistory.removeAll { $0.t < oldest }
        }
    }

    private func maxSpeed(since start: Double) -> Double {
        speedHistory.filter { $0.t >= start }.map { $0.kmh }.max() ?? 0
    }
}
