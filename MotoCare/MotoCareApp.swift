//
//  MotoCareApp.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 10/07/2026.
//

import SwiftUI

@main
struct MotoCareApp: App {
    
    @StateObject var globalViewModel = GarageViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalViewModel)
        }
    }
}
