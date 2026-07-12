//
//  DashboardView.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 11/07/2026.
//

import SwiftUI

struct DashboardView: View {
    // Usamos el modelo que creamos al principio para simular datos
    @State private var myBike = Motorcycle(make: "Kawasaki", model: "ER-6f", mileage: 15000)
    
    // Controla cuándo se abre la ventana flotante
    @State private var showAddMaintenance = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                
                // 1. Cabecera de saludo
                HStack {
                    VStack(alignment: .leading) {
                        Text("Hola, Piloto")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Aquí tienes el estado de tu garaje")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // 2. Tarjeta de la Moto Principal
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "motorcycle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(15)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(myBike.make) \(myBike.model)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("\(myBike.mileage) km")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 10)
                        Spacer()
                    }
                    
                    Divider()
                    
                    // 3. Alertas/Estado (Simulado)
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Todo en orden. Próxima revisión a los \(myBike.mileage + 5000) km.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(20)
                .padding(.horizontal)
                
                // 4. Acciones Rápidas
                Text("Acciones Rápidas")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                HStack(spacing: 15) {
                    ActionButton(icon: "wrench.and.screwdriver.fill", title: "Mantenimiento", color: .orange) {
                        showAddMaintenance = true
                    }
                    
                    ActionButton(icon: "fuelpump.fill", title: "Repostaje", color: .purple) {
                        print("Repostaje pulsado")
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationBarHidden(true)
        
        // MAGIA AQUÍ: Cuando el botón pone la variable en 'true', esto lanza la ventana
        .sheet(isPresented: $showAddMaintenance) {
            AddMaintenanceView()
        }
    }
}

// Subvista para los botones de acción rápida
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .padding(.bottom, 5)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
        }
    }
}

#Preview {
    DashboardView()
}
