//
//  CrashAlertView.swift
//  MotoCare
//
//  Pantalla de "posible accidente" (MVP paso 3, PROVISIONAL). Paleta FIJA de
//  alto contraste: la pantalla de emergencia nunca se tematiza con los colores
//  de la moto. En el paso 4 tendrá cuenta atrás, sonido, vibración y el aviso
//  a los contactos de emergencia; de momento no avisa a nadie.
//

import SwiftUI

struct CrashAlertView: View {
    let detection: CrashDetector.Detection
    let onImOK: () -> Void

    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))

                Text("¿Estás bien?")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))

                Text("Hemos detectado un posible accidente")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                details

                Spacer()

                Button(action: onImOK) {
                    Text("Estoy bien")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 90)
                        .background(Color.white)
                        .foregroundStyle(Color.red)
                        .cornerRadius(24)
                }

                Text("Prueba del paso 3: todavía no se avisa a nadie.")
                    .font(.footnote)
            }
            .foregroundStyle(.white)
            .padding(24)
        }
    }

    private var details: some View {
        VStack(spacing: 6) {
            Text(detection.confidence == .high
                 ? "Confianza ALTA: impacto, parada y quietud"
                 : "Confianza MEDIA: impacto y parada")
                .font(.headline)
            Text("Impacto \(detection.peakAccelerationG, format: .number.precision(.fractionLength(1))) g · giro \(detection.peakRotationDegPerSec, format: .number.precision(.fractionLength(0))) °/s")
            Text("Velocidad previa \(detection.speedBeforeKmh, format: .number.precision(.fractionLength(0))) km/h · quieto el \(Int((detection.stillFraction * 100).rounded())) % del tiempo")
        }
        .font(.subheadline.monospacedDigit())
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
}
