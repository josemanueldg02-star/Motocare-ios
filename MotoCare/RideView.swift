//
//  RideView.swift
//  MotoCare
//
//  Pantalla "Conducir": velocímetro en vivo, panel de sensores (MVP paso 2) y
//  botón para iniciar/finalizar el modo viaje. El botón es grande y va fijo
//  abajo a propósito: tiene que poder pulsarse con guantes.
//

import SwiftUI
import CoreLocation

struct RideView: View {
    @StateObject private var ride = RideSessionManager()

    private var locationBlocked: Bool {
        ride.authorizationStatus == .denied || ride.authorizationStatus == .restricted
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    speedometer

                    SensorPanel(sensors: ride.sensors,
                                isRiding: ride.isRiding,
                                recordingFailed: ride.recordingFailed)

                    if !ride.isRiding, let url = ride.lastRecordingURL {
                        shareRecording(url)
                    }

                    statusBanner
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                rideButton
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.bar)
            }
            .navigationTitle("Conducir")
            .onAppear {
                if ride.authorizationStatus == .notDetermined {
                    ride.requestPermission()
                }
            }
        }
    }

    // MARK: - Subvistas

    private var speedometer: some View {
        VStack(spacing: 8) {
            Text(ride.speedKmh, format: .number.precision(.fractionLength(0)))
                .font(.system(size: 110, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.3), value: Int(ride.speedKmh))
            Text("km/h")
                .font(.title3)
                .foregroundStyle(.secondary)

            if ride.isRiding {
                Label {
                    Text("Máx. \(ride.topSpeedKmh, format: .number.precision(.fractionLength(0))) km/h")
                } icon: {
                    Image(systemName: "gauge.high")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
        }
        .foregroundStyle(ride.isRiding ? .primary : .secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(24)
    }

    @ViewBuilder
    private var statusBanner: some View {
        if locationBlocked {
            VStack(spacing: 8) {
                Label("Ubicación desactivada", systemImage: "location.slash.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("MotoCare necesita el GPS para medir tu velocidad y, más adelante, detectar un posible accidente.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline.weight(.semibold))
            }
        } else if ride.isRiding {
            Label("Viaje en curso · vigilando", systemImage: "dot.radiowaves.left.and.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
        } else {
            Label("Pulsa «Iniciar viaje» antes de arrancar", systemImage: "info.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// Botón para enviar el CSV del último viaje (AirDrop al Mac, Archivos, etc.).
    private func shareRecording(_ url: URL) -> some View {
        VStack(spacing: 6) {
            ShareLink(item: url) {
                Label("Compartir grabación", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)

            Text(url.lastPathComponent)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var rideButton: some View {
        Button {
            if ride.isRiding { ride.stopRide() } else { ride.startRide() }
        } label: {
            Label(ride.isRiding ? "Finalizar viaje" : "Iniciar viaje",
                  systemImage: ride.isRiding ? "stop.fill" : "play.fill")
                .font(.title2.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(locationBlocked ? Color.gray : (ride.isRiding ? Color.red : Color.blue))
                .foregroundStyle(.white)
                .cornerRadius(18)
        }
        .disabled(locationBlocked)
    }
}

// MARK: - Panel de sensores

/// Acelerómetro y giroscopio en vivo, picos del viaje y estado de la grabación.
/// Observa SensorMonitor directamente: se refresca a 10 Hz sin redibujar toda la pantalla.
private struct SensorPanel: View {
    @ObservedObject var sensors: SensorMonitor
    let isRiding: Bool
    let recordingFailed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Sensores", systemImage: "waveform.path.ecg")
                .font(.headline)

            if !sensors.isAvailable {
                Text("Sensores de movimiento no disponibles en el simulador. Pruébalo en el iPhone.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 12) {
                    MetricTile(title: "Aceleración",
                               value: Text("\(sensors.accelerationG, format: .number.precision(.fractionLength(2))) g"))
                    MetricTile(title: "Giro",
                               value: Text("\(sensors.rotationDegPerSec, format: .number.precision(.fractionLength(0))) °/s"))
                }
                HStack(spacing: 12) {
                    MetricTile(title: "Inclinación",
                               value: Text("\(sensors.rollDeg, format: .number.precision(.fractionLength(0)))°"))
                    MetricTile(title: "Cabeceo",
                               value: Text("\(sensors.pitchDeg, format: .number.precision(.fractionLength(0)))°"))
                }

                Text("Pico del viaje: \(sensors.peakAccelerationG, format: .number.precision(.fractionLength(2))) g · \(sensors.peakRotationDegPerSec, format: .number.precision(.fractionLength(0))) °/s")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Toggle(isOn: $sensors.homeTestMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Modo prueba en casa")
                            .font(.subheadline.weight(.semibold))
                        Text("Ignora la velocidad. Inicia el viaje, deja caer el móvil en la cama y no lo toques unos 12 s.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.orange)

                if isRiding {
                    detectorStatus
                        .font(.subheadline.weight(.semibold))

                    recordingStatus

                    Button {
                        sensors.addMarker()
                    } label: {
                        Label("Marcar evento (\(sensors.markerCount))", systemImage: "flag.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)

                    Text("Usa «Marcar» solo con la moto parada, justo antes de cada prueba.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(24)
        .opacity(sensors.isRunning || !sensors.isAvailable ? 1 : 0.6)
        // Posible accidente → pantalla completa. "Estoy bien" la cierra y el detector vuelve a vigilar.
        .fullScreenCover(item: $sensors.detection) { detection in
            CrashAlertView(detection: detection) {
                sensors.detection = nil
            }
        }
    }

    @ViewBuilder
    private var detectorStatus: some View {
        switch sensors.detectorPhase {
        case .monitoring:
            Label(sensors.homeTestMode ? "Detector vigilando (modo prueba en casa)" : "Detector vigilando",
                  systemImage: "shield.checkered")
                .foregroundStyle(.green)
        case .impact:
            Label("Impacto detectado · comprobando si te detienes…", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .observing:
            Label("Detenido · comprobando si te mueves…", systemImage: "hourglass")
                .foregroundStyle(.orange)
        case .detected:
            Label("Posible accidente detectado", systemImage: "exclamationmark.octagon.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var recordingStatus: some View {
        if recordingFailed {
            Label("No se pudo grabar este viaje", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
        } else {
            Label {
                Text("Grabando · \(Duration.seconds(sensors.elapsedSeconds).formatted(.time(pattern: .hourMinuteSecond))) · \(sensors.sampleCount) muestras")
            } icon: {
                Image(systemName: "record.circle")
                    .foregroundStyle(.red)
            }
            .font(.subheadline.monospacedDigit())
        }
    }
}

/// Una casilla del panel: título pequeño y valor grande.
private struct MetricTile: View {
    let title: LocalizedStringKey
    let value: Text

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            value
                .font(.title3.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(14)
    }
}

#Preview {
    RideView()
}
