import SwiftUI

struct SplashView: View {
    // Binding nos permite modificar la variable que vive en ContentView
    @Binding var currentScreen: AppState
    
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
            
            // 2. Esperamos 2.5 segundos y cambiamos la pantalla al Login
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    currentScreen = .login
                }
            }
        }
    }
}
