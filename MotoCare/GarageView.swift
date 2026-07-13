//
//  GarageView.swift
//  MotoCare
//

import SwiftUI

struct GarageView: View {
    @EnvironmentObject var viewModel: GarageViewModel

    var body: some View {
        NavigationStack {
            List {
                if viewModel.maintenanceHistory.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.maintenanceHistory) { record in
                        recordRow(record)
                    }
                    .onDelete(perform: viewModel.deleteRecords) // swipe para borrar
                }
            }
            .navigationTitle("Mi Garaje")
            .toolbar {
                if !viewModel.maintenanceHistory.isEmpty {
                    EditButton()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 50))
                .foregroundStyle(.gray.opacity(0.5))
            Text("Tu historial está vacío.")
                .font(.headline)
            Text("Añade mantenimientos desde Inicio para verlos aquí.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func recordRow(_ record: MaintenanceRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.type)
                .font(.headline)
                .foregroundStyle(.blue)

            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.gray)
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
            }
            .font(.subheadline)

            HStack {
                Text("\(record.mileage.formatted()) km")
                Spacer()
                Text(record.cost.formatted(.currency(code: "EUR")))
                    .fontWeight(.bold)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    GarageView()
        .environmentObject(GarageViewModel())
}
