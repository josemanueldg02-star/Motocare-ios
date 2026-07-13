//
//  MotoCareApp.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 10/07/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
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
