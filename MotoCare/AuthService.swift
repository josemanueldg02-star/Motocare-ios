//
//  AuthService.swift
//  MotoCare
//
//  Lógica de autenticación local.
//  La contraseña NUNCA se guarda en claro: se almacena un hash SHA-256 con sal
//  en el Keychain. En producción esto viviría en un backend con un KDF lento
//  (bcrypt / argon2) y JWT; SHA-256 aquí es una demostración del patrón, no el fin.
//

import Foundation
import CryptoKit
import LocalAuthentication

enum AuthService {

    private static let saltKey = "motocare.auth.salt"
    private static let hashKey = "motocare.auth.passwordHash"

    /// Registra una contraseña: genera sal aleatoria, calcula el hash y lo guarda en Keychain.
    static func register(password: String) {
        let salt = UUID().uuidString
        let hash = hashPassword(password, salt: salt)
        KeychainHelper.save(salt, for: saltKey)
        KeychainHelper.save(hash, for: hashKey)
    }

    /// Verifica una contraseña contra el hash almacenado. No expone nunca el hash.
    static func verify(password: String) -> Bool {
        guard let salt = KeychainHelper.read(saltKey),
              let storedHash = KeychainHelper.read(hashKey) else {
            return false
        }
        return hashPassword(password, salt: salt) == storedHash
    }

    /// ¿Existe ya una cuenta registrada en este dispositivo?
    static func hasAccount() -> Bool {
        KeychainHelper.read(hashKey) != nil
    }

    /// Borra las credenciales del Keychain (por si quieres un "reset" real de cuenta).
    static func clearAccount() {
        KeychainHelper.delete(saltKey)
        KeychainHelper.delete(hashKey)
    }

    /// ¿El dispositivo puede evaluar biometría (Face ID / Touch ID)?
    static func biometricsAvailable() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // MARK: - Privado

    private static func hashPassword(_ password: String, salt: String) -> String {
        let data = Data((salt + password).utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
