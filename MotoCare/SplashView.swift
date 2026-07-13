//
//  SplashView.swift
//  MotoCare
//

import SwiftUI
import LocalAuthentication

struct SplashView: View {
    @Binding var currentScreen: AppState

    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("useFaceID") var useFaceID = false

    @State private var size = 0.5
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Motocare")
                    .font(.system(size: 45, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Image(systemName: "motorcycle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.blue)
            }
            .scaleEffect(size)
            .opacity(opacity)
        }
        .task {
            withAnimation(.easeIn(duration: 1.0)) {
                self.size = 1.0
                self.opacity = 1.0
            }
            // Espera de arranque sin bloquear el hilo con DispatchQueue.
            try? await Task.sleep(for: .seconds(2.5))
            checkLoginStatus()
        }
    }

    private func checkLoginStatus() {
        guard isLoggedIn else {
            withAnimation { currentScreen = .login }
            return
        }
        if useFaceID {
            authenticateWithFaceID()
        } else {
            withAnimation { currentScreen = .dashboard }
        }
    }

    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?

        // AGUJERO CORREGIDO: si no hay biometría, exigimos contraseña en vez de
        // dejar pasar directo al dashboard.
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            withAnimation { currentScreen = .login }
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "Inicia sesión en tu garaje") { success, _ in
            DispatchQueue.main.async {
                withAnimation { currentScreen = success ? .dashboard : .login }
            }
        }
    }
}

#Preview {
    SplashView(currentScreen: .constant(.splash))
}
