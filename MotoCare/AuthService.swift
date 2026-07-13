//
//  AuthService.swift
//  MotoCare
//
//  Autenticación local MULTIUSUARIO.
//  Cada cuenta se identifica por su email (normalizado). La contraseña se guarda
//  como hash SHA-256 con sal en el Keychain, bajo claves propias de cada email.
//  En producción esto sería un backend con tabla de usuarios + KDF lento (bcrypt/argon2).
//

import Foundation
import CryptoKit
import LocalAuthentication

enum AuthService {

    private static let accountsKey = "motocare.accounts"   // [String] de emails registrados

    /// ¿Ya existe una cuenta con ese correo?
    static func accountExists(email: String) -> Bool {
        registeredEmails().contains(normalize(email))
    }

    /// Registra un usuario nuevo. Devuelve false si el correo ya está en uso.
    @discardableResult
    static func register(email: String, password: String) -> Bool {
        let key = normalize(email)
        guard !key.isEmpty, !accountExists(email: key) else { return false }

        let salt = UUID().uuidString
        let hash = hashPassword(password, salt: salt)
        KeychainHelper.save(salt, for: saltKey(key))
        KeychainHelper.save(hash, for: hashKey(key))

        var emails = registeredEmails()
        emails.append(key)
        UserDefaults.standard.set(emails, forKey: accountsKey)
        return true
    }

    /// Verifica email + contraseña contra el hash almacenado de ESA cuenta.
    static func verify(email: String, password: String) -> Bool {
        let key = normalize(email)
        guard let salt = KeychainHelper.read(saltKey(key)),
              let storedHash = KeychainHelper.read(hashKey(key)) else {
            return false
        }
        return hashPassword(password, salt: salt) == storedHash
    }

    /// Normaliza un email para usarlo como identificador consistente.
    static func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func biometricsAvailable() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // MARK: - Privado

    private static func registeredEmails() -> [String] {
        UserDefaults.standard.stringArray(forKey: accountsKey) ?? []
    }

    private static func saltKey(_ email: String) -> String { "motocare.salt.\(email)" }
    private static func hashKey(_ email: String) -> String { "motocare.hash.\(email)" }

    private static func hashPassword(_ password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + password).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
