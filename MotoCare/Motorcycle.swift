//
//  Motorcycle.swift
//  MotoCare
//

import Foundation

struct Motorcycle: Identifiable, Codable, Equatable {
    var id = UUID()
    var make: String
    var model: String
    var mileage: Int                 // km actuales (Int, no String)
    var serviceIntervalKm: Int = 5000 // intervalo de revisión configurable
}
