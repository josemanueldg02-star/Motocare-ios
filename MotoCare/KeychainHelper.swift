//
//  KeychainHelper.swift
//  MotoCare
//
//  Almacenamiento seguro en el Keychain de iOS.
//  Reemplaza el uso de UserDefaults para datos sensibles (contraseñas).
//

import Foundation
import LocalAuthentication
import Security

enum KeychainHelper {

    /// Guarda un valor de texto asociado a una clave. Sobrescribe si ya existe.
    /// Si `requireBiometrics` es true, el valor queda protegido con `.biometryCurrentSet`:
    /// solo podrá leerse tras una autenticación biométrica válida con la biometría
    /// actualmente inscrita en el dispositivo (se invalida si el usuario cambia su Face ID/Touch ID).
    /// Devuelve false si el borrado previo, la creación del control de acceso o la inserción fallan.
    @discardableResult
    static func save(_ value: String, for key: String, requireBiometrics: Bool = false) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Primero borramos cualquier entrada previa con esa clave
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            return false
        }

        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        if requireBiometrics {
            guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                nil
            ) else {
                return false
            }
            addQuery[kSecAttrAccessControl as String] = accessControl
        } else {
            // Solo accesible cuando el dispositivo está desbloqueado.
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
    }

    /// Lee el valor de texto asociado a una clave. Devuelve nil si no existe o si la
    /// autenticación biométrica requerida (cuando el valor se guardó con `requireBiometrics`)
    /// no se supera. Si el ítem está protegido, esta llamada dispara el sheet de Face ID/Touch ID
    /// del sistema de forma síncrona. `prompt` personaliza el texto mostrado en ese sheet.
    static func read(_ key: String, prompt: String? = nil) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let prompt {
            let context = LAContext()
            context.localizedReason = prompt
            query[kSecUseAuthenticationContext as String] = context
        }

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
