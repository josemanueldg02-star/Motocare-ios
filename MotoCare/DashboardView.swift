//
//  DashboardView.swift
//  MotoCare
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: GarageViewModel

    @State private var showAddMaintenance = false
    @State private var showAddBike = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {

                // 1. Cabecera
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

                // 2. Tarjeta de moto (o estado vacío si el usuario aún no tiene ninguna)
                if let bike = viewModel.motorcycle {
                    bikeCard(bike)
                } else {
                    emptyBikeCard
                }

                // 3. Acciones Rápidas
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
            AddMaintenanceView().environmentObject(viewModel)
        }
        .sheet(isPresented: $showAddBike) {
            AddBikeView().environmentObject(viewModel)
        }
    }

    // MARK: - Subvistas

    private func bikeCard(_ bike: Motorcycle) -> some View {
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
                    Text("\(bike.make) \(bike.model)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(bike.mileage.formatted()) km")
                        .font(.headline)
                        .foregroundStyle(.gray)
                }
                .padding(.leading, 10)
                Spacer()
            }

            Divider()

            HStack {
                Image(systemName: viewModel.isServiceDue ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .foregroundStyle(viewModel.isServiceDue ? .orange : .green)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private var statusText: String {
        guard let next = viewModel.nextServiceMileage else { return "" }
        return viewModel.isServiceDue
            ? "Revisión pendiente. Superaste los \(next.formatted()) km."
            : "Todo en orden. Próxima revisión a los \(next.formatted()) km."
    }

    private var emptyBikeCard: some View {
        VStack(spacing: 15) {
            Image(systemName: "motorcycle")
                .font(.system(size: 50))
                .foregroundStyle(.gray.opacity(0.5))
            Text("Aún no tienes ninguna moto")
                .font(.headline)
            Text("Añade tu moto para empezar a llevar su mantenimiento.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            Button {
                showAddBike = true
            } label: {
                Text("Añadir moto")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
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
