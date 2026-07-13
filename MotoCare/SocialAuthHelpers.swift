//
//  SocialAuthHelpers.swift
//  MotoCare
//
//  Utilidades compartidas por las pantallas de Login/Registro para lanzar los
//  flujos nativos de Google y Apple.
//

import AuthenticationServices
import CryptoKit
import UIKit

enum SocialAuthHelpers {
    /// El view controller raíz de la ventana activa, necesario para presentar
    /// las hojas nativas de Google Sign-In.
    static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

/// Resultado de un login con Apple: el token de identidad, el nonce sin procesar
/// (para que Firebase valide el token) y el nombre completo (solo en el primer login).
struct AppleSignInResult {
    let idToken: String
    let rawNonce: String
    let fullName: PersonNameComponents?
}

/// Envuelve `ASAuthorizationController` (basado en delegates) en una API async/await.
@MainActor
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var currentNonce = ""

    func signIn() async throws -> AppleSignInResult {
        let nonce = Self.randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AuthServiceError(errorDescription: "No se pudo completar el inicio de sesión con Apple."))
            continuation = nil
            return
        }
        continuation?.resume(returning: AppleSignInResult(idToken: idToken, rawNonce: currentNonce, fullName: credential.fullName))
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            continuation?.resume(throwing: CancellationError())
        } else {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        SocialAuthHelpers.rootViewController?.view.window ?? ASPresentationAnchor()
    }

    // MARK: - Nonce

    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            guard status == errSecSuccess, random < charset.count else { continue }
            result.append(charset[Int(random)])
            remaining -= 1
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}
