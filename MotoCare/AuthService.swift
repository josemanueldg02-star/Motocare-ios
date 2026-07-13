//
//  AuthService.swift
//  MotoCare
//
//  Autenticación local MULTIUSUARIO.
//  Cada cuenta se identifica por su email (normalizado). La contraseña se guarda
//  como hash PBKDF2-HMAC-SHA256 con sal en el Keychain, bajo claves propias de cada email.
//  En producción esto sería un backend con tabla de usuarios + KDF lento (bcrypt/argon2).
//

import Foundation
import CommonCrypto
import LocalAuthentication

enum AuthService {

    private static let accountsKey = "motocare.accounts"   // [String] de emails registrados
    private static let pbkdf2Rounds: UInt32 = 100_000
    private static let saltByteCount = 16
    private static let derivedKeyByteCount = 32
    private static let maxFailedAttempts = 5
    private static let baseLockoutSeconds: TimeInterval = 30
    private static let maxLockoutSeconds: TimeInterval = 3600

    /// ¿Ya existe una cuenta con ese correo?
    static func accountExists(email: String) -> Bool {
        registeredEmails().contains(normalize(email))
    }

    /// Registra un usuario nuevo. Devuelve false si el correo ya está en uso.
    @discardableResult
    static func register(email: String, password: String) -> Bool {
        let key = normalize(email)
        guard !key.isEmpty, !accountExists(email: key) else { return false }

        let salt = randomSaltHex()
        let hash = hashPassword(password, saltHex: salt)

        guard KeychainHelper.save(salt, for: saltKey(key)),
              KeychainHelper.save(hash, for: hashKey(key), requireBiometrics: true) else {
            KeychainHelper.delete(saltKey(key))
            KeychainHelper.delete(hashKey(key))
            return false
        }

        var emails = registeredEmails()
        emails.append(key)
        UserDefaults.standard.set(emails, forKey: accountsKey)
        return true
    }

    /// Verifica email + contraseña contra el hash almacenado de ESA cuenta.
    /// Bloquea la cuenta temporalmente tras varios intentos fallidos consecutivos.
    static func verify(email: String, password: String) -> Bool {
        let key = normalize(email)

        if let lockedUntil = lockoutExpiry(for: key), lockedUntil > Date() {
            return false
        }

        guard let saltHex = KeychainHelper.read(saltKey(key)),
              let storedHash = KeychainHelper.read(
                hashKey(key),
                prompt: "Verifica tu identidad para iniciar sesión"
              ) else {
            return false
        }

        guard constantTimeCompare(hashPassword(password, saltHex: saltHex), storedHash) else {
            registerFailedAttempt(for: key)
            return false
        }

        clearFailedAttempts(for: key)
        return true
    }

    /// Segundos restantes de bloqueo por intentos fallidos, o nil si la cuenta no está bloqueada.
    static func lockoutRemaining(email: String) -> TimeInterval? {
        let key = normalize(email)
        guard let lockedUntil = lockoutExpiry(for: key) else { return nil }
        let remaining = lockedUntil.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
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
    private static func attemptsKey(_ email: String) -> String { "motocare.attempts.\(email)" }
    private static func lockoutKey(_ email: String) -> String { "motocare.lockout.\(email)" }

    private static func randomSaltHex() -> String {
        var bytes = [UInt8](repeating: 0, count: saltByteCount)
        arc4random_buf(&bytes, bytes.count)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func hashPassword(_ password: String, saltHex: String) -> String {
        let saltBytes = hexToBytes(saltHex)
        var derivedKey = [UInt8](repeating: 0, count: derivedKeyByteCount)

        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password, password.utf8.count,
            saltBytes, saltBytes.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            pbkdf2Rounds,
            &derivedKey, derivedKey.count
        )
        precondition(status == kCCSuccess, "PBKDF2 derivation failed")

        return derivedKey.map { String(format: "%02x", $0) }.joined()
    }

    private static func hexToBytes(_ hex: String) -> [UInt8] {
        var bytes = [UInt8]()
        bytes.reserveCapacity(hex.count / 2)
        var idx = hex.startIndex
        while idx < hex.endIndex {
            let next = hex.index(idx, offsetBy: 2)
            if let byte = UInt8(hex[idx..<next], radix: 16) {
                bytes.append(byte)
            }
            idx = next
        }
        return bytes
    }

    /// Compara dos cadenas byte a byte en tiempo constante (no aborta en la primera
    /// diferencia), para evitar filtrar por temporización cuántos bytes del hash coinciden.
    private static func constantTimeCompare(_ lhs: String, _ rhs: String) -> Bool {
        let lhsBytes = Array(lhs.utf8)
        let rhsBytes = Array(rhs.utf8)

        guard lhsBytes.count == rhsBytes.count else { return false }

        var diff: UInt8 = 0
        for i in 0..<lhsBytes.count {
            diff |= lhsBytes[i] ^ rhsBytes[i]
        }
        return diff == 0
    }

    /// Fecha hasta la que la cuenta permanece bloqueada, o nil si no hay bloqueo registrado.
    private static func lockoutExpiry(for key: String) -> Date? {
        guard let raw = KeychainHelper.read(lockoutKey(key)),
              let interval = TimeInterval(raw) else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    /// Suma un intento fallido y, a partir de `maxFailedAttempts`, aplica un bloqueo
    /// con espera creciente (backoff exponencial acotado a `maxLockoutSeconds`).
    private static func registerFailedAttempt(for key: String) {
        let attempts = (KeychainHelper.read(attemptsKey(key)).flatMap(Int.init) ?? 0) + 1
        KeychainHelper.save(String(attempts), for: attemptsKey(key))

        guard attempts >= maxFailedAttempts else { return }

        let extraFailures = attempts - maxFailedAttempts
        let lockoutSeconds = min(baseLockoutSeconds * pow(2, Double(extraFailures)), maxLockoutSeconds)
        let expiry = Date().addingTimeInterval(lockoutSeconds)
        KeychainHelper.save(String(expiry.timeIntervalSince1970), for: lockoutKey(key))
    }

    /// Limpia el contador de intentos fallidos y cualquier bloqueo tras un login correcto.
    private static func clearFailedAttempts(for key: String) {
        KeychainHelper.delete(attemptsKey(key))
        KeychainHelper.delete(lockoutKey(key))
    }
}
