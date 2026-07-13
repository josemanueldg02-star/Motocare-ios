//
//  AddMaintenanceView.swift
//  MotoCare
//

import SwiftUI

struct AddMaintenanceView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: GarageViewModel

    @State private var maintenanceType = "Cambio de Aceite"
    @State private var date = Date()
    @State private var mileage = ""
    @State private var cost = ""
    @State private var notes = ""

    let maintenanceOptions = ["Cambio de Aceite", "Neumáticos", "Frenos", "Kit de Arrastre", "Revisión General", "Otro"]

    // Validación real: los campos numéricos deben parsear a número, no solo "no estar vacíos".
    private var parsedMileage: Int? { Int(mileage) }
    private var parsedCost: Double? {
        // En España el teclado decimal escribe "," -> Double("45,5") es nil. Normalizamos.
        Double(cost.replacingOccurrences(of: ",", with: "."))
    }
    private var isFormValid: Bool { parsedMileage != nil && parsedCost != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalles principales")) {
                    Picker("Tipo de Mantenimiento", selection: $maintenanceType) {
                        ForEach(maintenanceOptions, id: \.self) { Text($0) }
                    }
                    DatePicker("Fecha", selection: $date, in: ...Date(), displayedComponents: .date)
                }

                Section(header: Text("Datos adicionales")) {
                    TextField("Kilometraje actual", text: $mileage)
                        .keyboardType(.numberPad)
                    TextField("Coste (€)", text: $cost)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Notas / Observaciones")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Añadir Registro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .fontWeight(.bold)
                        .disabled(!isFormValid)
                }
            }
        }
    }

    private func save() {
        guard let mileageValue = parsedMileage, let costValue = parsedCost else { return }
        viewModel.addRecord(
            type: maintenanceType,
            date: date,
            mileage: mileageValue,
            cost: costValue,
            notes: notes
        )
        dismiss()
    }
}

#Preview {
    AddMaintenanceView()
        .environmentObject(GarageViewModel())
}
