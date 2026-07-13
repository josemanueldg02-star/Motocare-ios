//
//  DashboardView.swift
//  MotoCare
//

import SwiftUI

struct DashboardView: View {
    // Ya NO hay una moto hardcodeada aquí. Se lee del ViewModel compartido.
    @EnvironmentObject var viewModel: GarageViewModel

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
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal)

                // 2. Tarjeta de la Moto Principal
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "motorcycle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(15)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(viewModel.motorcycle.make) \(viewModel.motorcycle.model)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("\(viewModel.motorcycle.mileage.formatted()) km")
                                .font(.headline)
                                .foregroundStyle(.gray)
                        }
                        .padding(.leading, 10)
                        Spacer()
                    }

                    Divider()

                    // 3. Estado real, derivado del historial (ya no es un texto fijo)
                    HStack {
                        Image(systemName: viewModel.isServiceDue ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .foregroundStyle(viewModel.isServiceDue ? .orange : .green)
                        Text(viewModel.isServiceDue
                             ? "Revisión pendiente. Superaste los \(viewModel.nextServiceMileage.formatted()) km."
                             : "Todo en orden. Próxima revisión a los \(viewModel.nextServiceMileage.formatted()) km.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
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
                        // TODO: pantalla de repostaje
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
        .sheet(isPresented: $showAddMaintenance) {
            AddMaintenanceView()
                .environmentObject(viewModel) // garantiza el modelo dentro del sheet
        }
    }
}

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
                    .foregroundStyle(color)
                    .padding(.bottom, 5)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(15)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(GarageViewModel())
}
