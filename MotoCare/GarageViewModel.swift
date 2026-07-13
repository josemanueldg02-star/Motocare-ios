//
//  GarageViewModel.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 12/07/2026.
//

import SwiftUI
import Foundation
import Combine

struct MaintenanceRecord: Identifiable, Codable {
    var id = UUID()
    let type: String
    let date: Date
    let mileage: String
    let cost: String
    let notes: String
}

class GarageViewModel: ObservableObject {
    
    @Published var maintenanceHistory: [MaintenanceRecord] = [] {
        didSet {
            saveData()
        }
    }
    
    let saveKey = "SavedMaintenanceHistory"
    
    init() {
        loadData()
    }
    
    // Función para añadir
    func addRecord(type: String, date: Date, mileage: String, cost: String, notes: String) {
        let newRecord = MaintenanceRecord(
            type: type,
            date: date,
            mileage: mileage,
            cost: cost,
            notes: notes
        )
        
        maintenanceHistory.insert(newRecord, at: 0)
    }
    
    // ==========================================
    //        NUEVAS FUNCIONES DE MEMORIA
    // ==========================================
    
    // Función para GUARDAR
    func saveData() {
        // Intentamos empaquetar nuestra lista en formato JSON
        if let encodedData = try? JSONEncoder().encode(maintenanceHistory) {
            // Si funciona, lo metemos en el cajón de UserDefaults con nuestra llave
            UserDefaults.standard.set(encodedData, forKey: saveKey)
        }
    }
    
    // Función para CARGAR
    func loadData() {
        // 1. Miramos si hay algo guardado en el cajón con nuestra llave
        if let savedData = UserDefaults.standard.data(forKey: saveKey) {
            // 2. Intentamos desempaquetar ese JSON y convertirlo de nuevo a [MaintenanceRecord]
            if let decodedRecords = try? JSONDecoder().decode([MaintenanceRecord].self, from: savedData) {
                // 3. Si todo va bien, se lo asignamos a nuestra lista
                maintenanceHistory = decodedRecords
                return
            }
        }
        
        // Si falla o no hay datos (ej. la primera vez que se abre la app), la lista empieza vacía
        maintenanceHistory = []
    }
}
