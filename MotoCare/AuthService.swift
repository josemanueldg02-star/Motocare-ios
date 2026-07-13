//
//  AuthService.swift
//  MotoCare
//
//  Autenticación MULTIUSUARIO respaldada por Firebase Auth.
//  El perfil (nombre, email, fecha de alta) se guarda en Firestore, en la
//  colección "users", usando como id el uid que asigna Firebase Auth.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn
import LocalAuthentication
import UIKit

struct AppUser: Codable {
    let uid: String
    let name: String
    let email: String
    let phoneNumber: String?
    let createdAt: Date

    /// Email o, si no hay (cuentas de solo teléfono), el número de teléfono.
    var displayIdentifier: String {
        if !email.isEmpty { return email }
        return phoneNumber ?? ""
    }
}

struct AuthServiceError: LocalizedError {
    let errorDescription: String?
}

enum AuthService {

    private static let db = Firestore.firestore()

    /// Registra un usuario nuevo en Firebase Auth y crea su perfil en Firestore.
    @discardableResult
    static func register(name: String, email: String, password: String) async throws -> AppUser {
        let cleanEmail = normalize(email)
        do {
            let result = try await Auth.auth().createUser(withEmail: cleanEmail, password: password)

            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try? await changeRequest.commitChanges()

            let user = AppUser(uid: result.user.uid, name: name, email: cleanEmail, phoneNumber: nil, createdAt: Date())
            try await db.collection("users").document(user.uid).setData(from: user)
            return user
        } catch {
            throw AuthServiceError(errorDescription: spanishMessage(for: error))
        }
    }

    /// Inicia sesión con email y contraseña contra Firebase Auth.
    static func login(email: String, password: String) async throws -> AppUser {
        let cleanEmail = normalize(email)
        do {
            let result = try await Auth.auth().signIn(withEmail: cleanEmail, password: password)
            return try await fetchOrCreateProfile(for: result.user, defaultName: nil)
        } catch {
            throw AuthServiceError(errorDescription: spanishMessage(for: error))
        }
    }

    /// Inicia sesión (o registra, si es la primera vez) con una cuenta de Google.
    static func signInWithGoogle(presenting viewController: UIViewController) async throws -> AppUser {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthServiceError(errorDescription: "Falta configurar Firebase (GoogleService-Info.plist).")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        do {
            let googleResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            guard let idToken = googleResult.user.idToken?.tokenString else {
                throw AuthServiceError(errorDescription: "No se pudo obtener el token de Google.")
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: googleResult.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            return try await fetchOrCreateProfile(for: authResult.user, defaultName: googleResult.user.profile?.name)
        } catch let signInError as GIDSignInError where signInError.code == .canceled {
            throw CancellationError()
        } catch {
            throw AuthServiceError(errorDescription: spanishMessage(for: error))
        }
    }

    /// Inicia sesión (o registra, si es la primera vez) con una cuenta de Apple.
    /// `rawNonce` debe ser el mismo valor (sin procesar) usado al crear la petición
    /// de `ASAuthorizationAppleIDProvider`, para que Firebase pueda validar el token.
    static func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> AppUser {
        let credential = OAuthProvider.credential(providerID: .apple, idToken: idToken, rawNonce: rawNonce)
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            let name = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            return try await fetchOrCreateProfile(for: authResult.user, defaultName: name.isEmpty ? nil : name)
        } catch {
            throw AuthServiceError(errorDescription: spanishMessage(for: error))
        }
    }

    /// Envía un SMS con un código a `phoneNumber` (formato E.164, ej. "+34612345678").
    /// Devuelve un identificador de verificación que hay que guardar y pasar a
    /// `confirmPhoneCode` junto con el código que introduzca el usuario.
    static func sendPhoneVerificationCode(phoneNumber: String) async throws -> String {
        do {
            return try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
        } catch {
            throw AuthServiceError(errorDescription: spanishMessage(for: error))
        }
    }

    /// Completa el login (o registro, si es la primera vez) verificando el código de SMS.
    static func confirmPhoneCode(verificationID: String, code: String) async throws -> AppUser {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            return try await fetchOrCreateProfile(for: authResult.user, defaultName: nil)
        } catch {
            throw AuthServiceError(errorDescription: spanishMessage(for: error))
        }
    }

    /// Cierra la sesión activa.
    static func logout() throws {
        try Auth.auth().signOut()
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

    /// Recupera el perfil de Firestore tras un login; si no existiera (primer acceso con
    /// Google/Apple, o cuenta creada fuera de la app), lo crea. `defaultName` solo se usa
    /// para ese primer alta, ya que Google/Apple únicamente entregan el nombre una vez.
    private static func fetchOrCreateProfile(for user: User, defaultName: String?) async throws -> AppUser {
        let ref = db.collection("users").document(user.uid)
        if let snapshot = try? await ref.getDocument(), snapshot.exists,
           let existing = try? snapshot.data(as: AppUser.self) {
            return existing
        }
        let name = defaultName ?? user.displayName ?? ""
        let fallback = AppUser(uid: user.uid, name: name, email: user.email ?? "", phoneNumber: user.phoneNumber, createdAt: Date())
        try await ref.setData(from: fallback)
        return fallback
    }

    private static func spanishMessage(for error: Error) -> String {
        let nsError = error as NSError
        print("🔥 AuthService error → domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo)")

        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return "No se pudo completar la operación. Inténtalo de nuevo."
        }
        switch code {
        case .invalidEmail: return "El correo introducido no es válido."
        case .emailAlreadyInUse: return "Ya existe una cuenta con ese correo. Inicia sesión."
        case .weakPassword: return "La contraseña debe tener al menos 6 caracteres."
        case .wrongPassword, .invalidCredential: return "Correo o contraseña incorrectos."
        case .invalidPhoneNumber: return "El número de teléfono no es válido. Incluye el prefijo del país (ej. +34)."
        case .invalidVerificationCode: return "El código introducido no es correcto."
        case .sessionExpired: return "El código ha caducado. Solicita uno nuevo."
        case .quotaExceeded: return "Se ha superado el límite de SMS. Inténtalo más tarde."
        case .missingPhoneNumber: return "Introduce un número de teléfono."
        case .userNotFound: return "No existe ninguna cuenta con ese correo."
        case .networkError: return "Sin conexión. Comprueba tu red e inténtalo de nuevo."
        case .tooManyRequests: return "Demasiados intentos. Espera un momento antes de volver a intentarlo."
        default: return "No se pudo completar la operación. Inténtalo de nuevo."
        }
    }
}
