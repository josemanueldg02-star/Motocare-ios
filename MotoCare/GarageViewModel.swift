//
//  GarageViewModel.swift
//  MotoCare
//

import SwiftUI
import Foundation
import Combine

struct MaintenanceRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: String
    var date: Date
    var mileage: Int   // Int, no String
    var cost: Double   // Double, no String
    var notes: String
}

@MainActor
final class GarageViewModel: ObservableObject {

    // Fuente ÚNICA de verdad de la moto: ya no vive suelta en DashboardView.
    @Published var motorcycle: Motorcycle {
        didSet { save() }
    }

    @Published private(set) var maintenanceHistory: [MaintenanceRecord] = [] {
        didSet { save() }
    }

    private static let historyKey = "SavedMaintenanceHistory"
    private static let bikeKey = "SavedMotorcycle"

    init() {
        // Cargamos la moto guardada o usamos una por defecto la primera vez.
        self.motorcycle = Self.load(Motorcycle.self, key: Self.bikeKey)
            ?? Motorcycle(make: "Kawasaki", model: "ER-6f", mileage: 21560)
        self.maintenanceHistory = Self.load([MaintenanceRecord].self, key: Self.historyKey) ?? []
    }

    // MARK: - Operaciones

    func addRecord(type: String, date: Date, mileage: Int, cost: Double, notes: String) {
        let record = MaintenanceRecord(type: type, date: date, mileage: mileage, cost: cost, notes: notes)
        maintenanceHistory.append(record)
        maintenanceHistory.sort { $0.date > $1.date }   // más reciente primero

        // Si el mantenimiento tiene un km mayor, la moto queda al día automáticamente.
        if mileage > motorcycle.mileage {
            motorcycle.mileage = mileage
        }
    }

    func deleteRecords(at offsets: IndexSet) {
        maintenanceHistory.remove(atOffsets: offsets)
    }

    // MARK: - Estado derivado (conecta datos que antes estaban desconectados)

    /// Km al que toca la próxima revisión, a partir del último mantenimiento registrado.
    var nextServiceMileage: Int {
        let lastServiceMileage = maintenanceHistory.map(\.mileage).max() ?? motorcycle.mileage
        return lastServiceMileage + motorcycle.serviceIntervalKm
    }

    var isServiceDue: Bool {
        motorcycle.mileage >= nextServiceMileage
    }

    var totalSpent: Double {
        maintenanceHistory.reduce(0) { $0 + $1.cost }
    }

    // MARK: - Persistencia

    private func save() {
        if let history = try? JSONEncoder().encode(maintenanceHistory) {
            UserDefaults.standard.set(history, forKey: Self.historyKey)
        }
        if let bike = try? JSONEncoder().encode(motorcycle) {
            UserDefaults.standard.set(bike, forKey: Self.bikeKey)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
