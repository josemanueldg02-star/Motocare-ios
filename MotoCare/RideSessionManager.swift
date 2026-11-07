//
//  RideSessionManager.swift
//  MotoCare
//
//  "Modo viaje": pide permiso de ubicación, arranca/para el seguimiento GPS y
//  publica la velocidad actual en km/h. Es la base del futuro detector de
//  accidentes (MVP paso 1: de momento solo mide la velocidad en vivo, también
//  con la app en segundo plano).
//

import Foundation
import Combine
import CoreLocation

final class RideSessionManager: NSObject, ObservableObject {

    /// Velocidad actual en km/h (0 si el GPS aún no da un valor válido).
    @Published private(set) var speedKmh: Double = 0
    /// Velocidad máxima alcanzada en el viaje actual.
    @Published private(set) var topSpeedKmh: Double = 0
    @Published private(set) var isRiding = false
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .otherNavigation
        // Que iOS no "pause" el GPS por su cuenta en mitad de un viaje.
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }

    /// Pide permiso de ubicación "mientras se usa la app".
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startRide() {
        guard !isRiding else { return }
        switch authorizationStatus {
        case .notDetermined:
            // El seguimiento arrancará solo en cuanto el usuario conceda el permiso.
            requestPermission()
        case .denied, .restricted:
            return
        default:
            break
        }
        isRiding = true
        topSpeedKmh = 0
        beginUpdatesIfPossible()
    }

    func stopRide() {
        isRiding = false
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        speedKmh = 0
    }

    private func beginUpdatesIfPossible() {
        guard isRiding,
              authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        else { return }
        // Mantiene el GPS vivo con la app en segundo plano.
        // OJO: exige UIBackgroundModes → location en Info.plist; sin eso, iOS cierra la app.
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
// El manager se crea en el hilo principal, así que iOS entrega estos callbacks
// en el principal y podemos actualizar las propiedades @Published directamente.

extension RideSessionManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isRiding { beginUpdatesIfPossible() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // location.speed viene en m/s y vale -1 cuando no es fiable.
        let kmh = max(0, location.speed) * 3.6
        speedKmh = kmh
        if kmh > topSpeedKmh { topSpeedKmh = kmh }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // MVP: un fallo puntual del GPS no detiene el viaje; seguimos esperando lecturas.
        #if DEBUG
        print("📍 RideSessionManager error: \(error.localizedDescription)")
        #endif
    }
}
