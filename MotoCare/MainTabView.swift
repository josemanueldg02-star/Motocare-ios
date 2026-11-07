//
//  MainTabView.swift
//  MotoCare
//

import SwiftUI

struct MainTabView: View {
    @Binding var currentScreen: AppState

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Inicio")
                }

            RideView()
                .tabItem {
                    Image(systemName: "gauge.high")
                    Text("Conducir")
                }

            GarageView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("Mi Garaje")
                }

            ProfileView(currentScreen: $currentScreen)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Perfil")
                }
        }
        .tint(.blue) // antes .accentColor (deprecado)
    }
}

#Preview {
    MainTabView(currentScreen: .constant(.dashboard))
        .environmentObject(GarageViewModel())
}
