//
//  GarageViewModel.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 12/07/2026.
//

import SwiftUI
import Foundation
import Combine

// 1. EL MOLDE: Definimos qué datos componen un registro de mantenimiento
struct MaintenanceRecord: Identifiable {
    let id = UUID() // Identificador único generado automáticamente por Apple
    let type: String
    let date: Date
    let mileage: String
    let cost: String
    let notes: String
}

// 2. EL CEREBRO: Guarda la lista y gestiona los datos
class GarageViewModel: ObservableObject {
    
    // @Published es mágico: si esta lista cambia, avisa a las pantallas para que se actualicen solas
    @Published var maintenanceHistory: [MaintenanceRecord] = []
    
    // Función que usaremos desde el botón "Guardar" para añadir un registro
    func addRecord(type: String, date: Date, mileage: String, cost: String, notes: String) {
        let newRecord = MaintenanceRecord(
            type: type,
            date: date,
            mileage: mileage,
            cost: cost,
            notes: notes
        )
        
        // Insertamos el nuevo registro en la posición 0 (el principio) para ver el más reciente primero
        maintenanceHistory.insert(newRecord, at: 0)
    }
}
