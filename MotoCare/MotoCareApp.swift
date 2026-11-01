//
//  MotoCareApp.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 10/07/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck
import GoogleSignIn

/// Elige el proveedor de App Check según el dispositivo:
/// App Attest en iOS 14+ (hardware seguro) y DeviceCheck como respaldo.
/// Solo se usa en builds de release; en DEBUG usamos el proveedor de depuración.
final class MotoCareAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        }
        return DeviceCheckProvider(app: app)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // App Check DEBE configurarse ANTES de FirebaseApp.configure().
        // Protege el backend (Auth, Firestore) para que solo responda a esta app
        // genuina y no a clientes falsos, scripts o abuso del envío de SMS.
        #if DEBUG
        // En simulador/desarrollo imprime un "debug token" en la consola que hay que
        // registrar en: Firebase Console → App Check → tu app → Manage debug tokens.
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(MotoCareAppCheckProviderFactory())
        #endif

        FirebaseApp.configure()
        application.registerForRemoteNotifications()
        return true
    }

    // Sin capability de Push Notifications no llega un token real, pero declarar estos
    // métodos es lo que permite a Firebase confirmar que "reenviaríamos" la notificación
    // y recurrir al reCAPTCHA para verificar el teléfono en vez de fallar directamente.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { }

    func application(_ application: UIApplication,
                      didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                      fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.newData)
    }
}

@main
struct MotoCareApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var globalViewModel = GarageViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalViewModel)
                .onOpenURL { url in
                    if Auth.auth().canHandle(url) { return }
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
