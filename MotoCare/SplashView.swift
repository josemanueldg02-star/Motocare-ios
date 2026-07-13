import SwiftUI
import LocalAuthentication // Para poder usar FaceID al arrancar

struct SplashView: View {
    @Binding var currentScreen: AppState
    
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("useFaceID") var useFaceID = false // Saber si activó FaceID
    
    // Variables para la animación inicial
    @State private var size = 0.5
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            // Fondo para asegurar el centrado absoluto en toda la pantalla
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Motocare")
                    .font(.system(size: 45, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                
                // Asegúrate de que "motorcycle" esté todo en minúsculas
                Image(systemName: "motorcycle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
            }
            .scaleEffect(size)
            .opacity(opacity)
        }
        .onAppear {
            // 1. Efecto de aparición suave (1 segundo)
            withAnimation(.easeIn(duration: 1.0)) {
                self.size = 1.0
                self.opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                checkLoginStatus() // <- CAMBIADO: Llamamos a la nueva lógica
            }
        }
    }
    
    // ==========================================
    //        NUEVAS FUNCIONES DE ARRANQUE
    // ==========================================

    func checkLoginStatus() {
        if isLoggedIn {
            if useFaceID {
                // Si está logueado y activó FaceID, lo pedimos
                authenticateWithFaceID()
            } else {
                // Si está logueado pero NO activó FaceID, entra directo
                withAnimation { currentScreen = .dashboard }
            }
        } else {
            // No está logueado
            withAnimation { currentScreen = .login }
        }
    }

    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Inicia sesión en tu garaje") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        withAnimation { currentScreen = .dashboard }
                    } else {
                        // Si cancela o no reconoce la cara, le mandamos a poner la contraseña
                        withAnimation { currentScreen = .login }
                    }
                }
            }
        } else {
            withAnimation { currentScreen = .dashboard }
        }
    }
}
