//
//  RideView.swift
//  MotoCare
//
//  Pantalla "Conducir": velocímetro en vivo y botón para iniciar/finalizar el
//  modo viaje. Botón grande a propósito: tiene que poder pulsarse con guantes.
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
            VStack(spacing: 24) {
                Spacer()

                speedometer

                Spacer()

                statusBanner

                rideButton
            }
            .padding()
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

#Preview {
    RideView()
}
