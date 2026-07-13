//
//  GarageViewModel.swift
//  MotoCare
//
//  Datos POR USUARIO. Cada email tiene su propia moto e historial, guardados
//  bajo claves con espacio de nombres (garage.<email>.bike / .history).
//  Un usuario nuevo empieza SIN moto (motorcycle == nil) y con historial vacío.
//

import SwiftUI
import Foundation
import Combine

struct MaintenanceRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: String
    var date: Date
    var mileage: Int
    var cost: Double
    var notes: String
}

@MainActor
final class GarageViewModel: ObservableObject {

    @Published private(set) var currentUserEmail: String?
    @Published var motorcycle: Motorcycle? { didSet { if !isLoading { save() } } }
    @Published private(set) var maintenanceHistory: [MaintenanceRecord] = [] { didSet { if !isLoading { save() } } }

    private var isLoading = false

    init(userEmail: String? = nil) {
        self.currentUserEmail = userEmail
        self.motorcycle = nil
        self.maintenanceHistory = []
        loadForCurrentUser()
    }

    // MARK: - Sesión

    /// Cambia el usuario activo y recarga SUS datos. Con nil, deja todo vacío.
    func switchToUser(email: String?) {
        currentUserEmail = email
        loadForCurrentUser()
    }

    // MARK: - Moto

    /// Crea o actualiza la moto del usuario actual (conserva el id si ya existía).
    func setMotorcycle(make: String, model: String, mileage: Int, serviceIntervalKm: Int = 5000) {
        if var bike = motorcycle {
            bike.make = make
            bike.model = model
            bike.mileage = mileage
            bike.serviceIntervalKm = serviceIntervalKm
            motorcycle = bike
        } else {
            motorcycle = Motorcycle(make: make, model: model, mileage: mileage, serviceIntervalKm: serviceIntervalKm)
        }
    }

    // MARK: - Mantenimientos

    func addRecord(type: String, date: Date, mileage: Int, cost: Double, notes: String) {
        let record = MaintenanceRecord(type: type, date: date, mileage: mileage, cost: cost, notes: notes)
        maintenanceHistory.append(record)
        maintenanceHistory.sort { $0.date > $1.date }

        // Si registramos un km mayor, la moto queda al día (si existe).
        if var bike = motorcycle, mileage > bike.mileage {
            bike.mileage = mileage
            motorcycle = bike
        }
    }

    func deleteRecords(at offsets: IndexSet) {
        maintenanceHistory.remove(atOffsets: offsets)
    }

    // MARK: - Estado derivado

    var nextServiceMileage: Int? {
        guard let bike = motorcycle else { return nil }
        let lastServiceMileage = maintenanceHistory.map(\.mileage).max() ?? bike.mileage
        return lastServiceMileage + bike.serviceIntervalKm
    }

    var isServiceDue: Bool {
        guard let bike = motorcycle, let next = nextServiceMileage else { return false }
        return bike.mileage >= next
    }

    var totalSpent: Double {
        maintenanceHistory.reduce(0) { $0 + $1.cost }
    }

    // MARK: - Persistencia por usuario

    private func loadForCurrentUser() {
        isLoading = true
        defer { isLoading = false }

        guard let email = currentUserEmail else {
            motorcycle = nil
            maintenanceHistory = []
            return
        }
        motorcycle = Self.decode(Motorcycle.self, key: Self.bikeKey(email))
        maintenanceHistory = Self.decode([MaintenanceRecord].self, key: Self.historyKey(email)) ?? []
    }

    private func save() {
        guard let email = currentUserEmail else { return } // sin usuario, no persistimos nada

        if let bike = motorcycle, let data = try? JSONEncoder().encode(bike) {
            UserDefaults.standard.set(data, forKey: Self.bikeKey(email))
        } else {
            UserDefaults.standard.removeObject(forKey: Self.bikeKey(email))
        }

        if let data = try? JSONEncoder().encode(maintenanceHistory) {
            UserDefaults.standard.set(data, forKey: Self.historyKey(email))
        }
    }

    private static func bikeKey(_ email: String) -> String { "garage.\(email).bike" }
    private static func historyKey(_ email: String) -> String { "garage.\(email).history" }

    private static func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
