//
//  AddMaintenanceView.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 12/07/2026.
//

import SwiftUI

struct AddMaintenanceView: View {
    @Environment(\.dismiss) var dismiss
    
    // Variables temporales para guardar lo que escribe el usuario
    @State private var maintenanceType = "Cambio de Aceite"
    @State private var date = Date()
    @State private var mileage = ""
    @State private var cost = ""
    @State private var notes = ""
    
    let maintenanceOptions = ["Cambio de Aceite", "Neumáticos", "Frenos", "Kit de Arrastre", "Revisiones", "Otros"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalles principales")) {
                    Picker("Tipo de Mantenimiento", selection: $maintenanceType) {
                        ForEach(maintenanceOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    
                    DatePicker("Fecha", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Datos adicionales")) {
                    TextField("Kilometraje actual", text: $mileage)
                        .keyboardType(.numberPad) // Para forzar el teclado numérico.
                    
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
                // Colocamos botones en la barra superior
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        print("Guardado mantenimiento: \(maintenanceType)")
                        // Conectar a lista "Mi Garaje".
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    AddMaintenanceView()
}
