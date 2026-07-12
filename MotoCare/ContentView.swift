//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 10/07/2026.
//

import SwiftUI

// Los estados por los que puede pasar nuestra app
enum AppState {
    case splash
    case login
    case dashboard
}

struct ContentView: View {
    // Empezamos siempre en la pantalla de carga
    @State private var currentScreen: AppState = .splash
    
    var body: some View {
        Group {
            // El "Enrutador": Decide qué pantalla mostrar
            switch currentScreen {
            case .splash:
                SplashView(currentScreen: $currentScreen)
            case .login:
                LoginView(currentScreen: $currentScreen)
            case .dashboard:
                MainTabView()
            }
        }
    }
}

#Preview {
    ContentView()
}
