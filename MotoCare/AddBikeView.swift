//
//  AddBikeView.swift
//  MotoCare
//
//  Alta / edición de la moto del usuario actual. Sirve tanto para dar de alta
//  la primera moto (usuario recién registrado) como para editarla luego.
//

import SwiftUI

struct AddBikeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: GarageViewModel

    @State private var make: String
    @State private var model: String
    @State private var mileage: String
    @State private var interval: String

    private let isEditing: Bool

    init(existing: Motorcycle? = nil) {
        self.isEditing = existing != nil
        _make = State(initialValue: existing?.make ?? "")
        _model = State(initialValue: existing?.model ?? "")
        _mileage = State(initialValue: existing.map { String($0.mileage) } ?? "")
        _interval = State(initialValue: existing.map { String($0.serviceIntervalKm) } ?? "5000")
    }

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(mileage) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Datos de la moto")) {
                    TextField("Marca (ej. Kawasaki)", text: $make)
                    TextField("Modelo (ej. ER-6f)", text: $model)
                    TextField("Kilometraje actual", text: $mileage)
                        .keyboardType(.numberPad)
                }
                Section(header: Text("Mantenimiento"),
                        footer: Text("Cada cuántos km quieres que te avise de la próxima revisión.")) {
                    TextField("Intervalo de revisión (km)", text: $interval)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(isEditing ? "Editar moto" : "Añadir moto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .fontWeight(.bold)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard let km = Int(mileage) else { return }
        viewModel.setMotorcycle(
            make: make.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            mileage: km,
            serviceIntervalKm: Int(interval) ?? 5000
        )
        dismiss()
    }
}

#Preview {
    AddBikeView()
        .environmentObject(GarageViewModel())
}
