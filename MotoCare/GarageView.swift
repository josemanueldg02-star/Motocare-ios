//
//  GarageView.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 12/07/2026.
//

import SwiftUI

struct GarageView: View {
    @ObservedObject var viewModel: GarageViewModel
    var body: some View {
        NavigationStack {
            List {
                if viewModel.maintenanceHistory.isEmpty {
                    // Mostramos un mensaje si no hay nada.
                    VStack(alignment: .center, spacing: 10) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size:50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Tu historial está vacío.")
                            .font(.headline)
                        
                        Text("Añade mantenimientos desde Inicio para verlos aquí.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.maintenanceHistory) { record in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(record.type)
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                            }
                            .font(.subheadline)
                            
                            HStack {
                                Text("km: \(record.mileage)")
                                Spacer()
                                Text("Coste: \(record.cost) €")
                                    .fontWeight(.bold)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Mi Garaje")
        }
    }
}

#Preview {
    GarageView(viewModel: GarageViewModel())
}
