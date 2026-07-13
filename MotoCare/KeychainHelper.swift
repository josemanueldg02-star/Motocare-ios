//
//  KeychainHelper.swift
//  MotoCare
//
//  Almacenamiento seguro en el Keychain de iOS.
//  Reemplaza el uso de UserDefaults para datos sensibles (contraseñas).
//

import Foundation
import Security

enum KeychainHelper {

    /// Guarda un valor de texto asociado a una clave. Sobrescribe si ya existe.
    static func save(_ value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Primero borramos cualquier entrada previa con esa clave
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Insertamos el nuevo valor. Solo accesible cuando el dispositivo está desbloqueado.
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    /// Lee el valor de texto asociado a una clave. Devuelve nil si no existe.
    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    /// Elimina el valor asociado a una clave.
    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
