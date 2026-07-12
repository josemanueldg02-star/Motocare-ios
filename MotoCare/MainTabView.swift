//
//  MainTabView.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 12/07/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Pestaña 1: Dashboard.
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Inicio")
                }
            // Pestaña 2: Historial/Garaje (En construcción).
            Text("Aquí irá la lista de mantenimiento de tu moto.")
                .font(.headline)
                .foregroundColor(.gray)
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("Mi Garaje")
                }
            
            // Pestaña 3: Perfil (En construcción).
            Text("Aquí irán los ajustes y datos del piloto")
                .font(.headline)
                .foregroundColor(.gray)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Perfil")
                }
            
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
}
