//
//  ContentView.swift
//  MotoCare
//

import SwiftUI

// Los estados por los que puede pasar la app
enum AppState {
    case splash
    case login
    case dashboard
}

struct ContentView: View {
    @State private var currentScreen: AppState = .splash

    var body: some View {
        Group {
            switch currentScreen {
            case .splash:
                SplashView(currentScreen: $currentScreen)
            case .login:
                LoginView(currentScreen: $currentScreen)
            case .dashboard:
                MainTabView(currentScreen: $currentScreen) // ahora recibe el binding (permite logout)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GarageViewModel())
}
