//
//  LoginView.swift
//  MotoCare
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @Binding var currentScreen: AppState
    @EnvironmentObject var viewModel: GarageViewModel

    @AppStorage("currentUserID") var currentUserID = ""
    @AppStorage("currentUserDisplay") var currentUserDisplay = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("useFaceID") var useFaceID = false

    @State private var emailInput = ""
    @State private var passwordInput = ""
    @State private var isLoading = false
    @State private var appleCoordinator = AppleSignInCoordinator()

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showFaceIDPrompt = false
    @State private var showPhoneAuth = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Spacer()

                Image(systemName: "motorcycle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue)

                Text("Bienvenido a Motocare")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Tu Taller Virtual en el bolsillo")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.bottom, 20)

                VStack(spacing: 15) {
                    CustomTextField(icon: "envelope.fill", placeholder: "Correo electrónico", text: $emailInput)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    CustomSecureField(icon: "lock.fill", placeholder: "Contraseña", text: $passwordInput)

                    Button(action: loginWithEmail) {
                        ZStack {
                            Text("Iniciar Sesión")
                                .opacity(isLoading ? 0 : 1)
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)

                    // Face ID reentra en la ÚLTIMA cuenta usada, si el usuario lo activó.
                    if !currentUserID.isEmpty && useFaceID && AuthService.biometricsAvailable() {
                        Button(action: authenticateWithBiometrics) {
                            HStack {
                                Image(systemName: "faceid")
                                    .font(.title2)
                                Text("Entrar con Face ID")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)

                VStack(spacing: 15) {
                    HStack {
                        VStack { Divider() }
                        Text("O continúa con")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                        VStack { Divider() }
                    }
                    .padding(.vertical, 5)

                    HStack(spacing: 25) {
                        SocialLoginButton(icon: "applelogo", color: .primary) { loginWithApple() }
                        SocialLoginTextButton(text: "G", color: .red) { loginWithGoogle() }
                        SocialLoginButton(icon: "phone.fill", color: .green) { showPhoneAuth = true }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                NavigationLink(destination: RegisterView(currentScreen: $currentScreen)) {
                    Text("¿No tienes cuenta? **Regístrate**")
                        .foregroundStyle(.blue)
                        .padding(.bottom, 20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Error de Inicio", isPresented: $showError) {
                Button("Entendido", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("¿Activar Face ID?", isPresented: $showFaceIDPrompt) {
                Button("Sí, activar") {
                    useFaceID = true
                    currentScreen = .dashboard
                }
                Button("No, gracias", role: .cancel) {
                    useFaceID = false
                    currentScreen = .dashboard
                }
            } message: {
                Text("Has iniciado sesión correctamente. ¿Quieres usar Face ID para entrar más rápido la próxima vez?")
            }
            .sheet(isPresented: $showPhoneAuth) {
                PhoneAuthView { user in
                    applyLogin(user)
                    proceedAfterLogin()
                }
            }
        }
    }

    // MARK: - Lógica

    /// Aplica el resultado de cualquier método de login (email, Google, Apple o teléfono).
    private func applyLogin(_ user: AppUser) {
        currentUserID = user.uid
        currentUserDisplay = user.displayIdentifier
        viewModel.switchToUser(userID: user.uid) // carga los datos de ESTE usuario
        isLoggedIn = true
    }

    private func loginWithEmail() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let user = try await AuthService.login(email: emailInput, password: passwordInput)
                applyLogin(user)
                proceedAfterLogin()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func loginWithGoogle() {
        guard let rootVC = SocialAuthHelpers.rootViewController else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let user = try await AuthService.signInWithGoogle(presenting: rootVC)
                applyLogin(user)
                proceedAfterLogin()
            } catch is CancellationError {
                // El usuario canceló el diálogo de Google; no mostramos error.
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func loginWithApple() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let result = try await appleCoordinator.signIn()
                let user = try await AuthService.signInWithApple(idToken: result.idToken, rawNonce: result.rawNonce, fullName: result.fullName)
                applyLogin(user)
                proceedAfterLogin()
            } catch is CancellationError {
                // El usuario canceló el diálogo de Apple; no mostramos error.
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func proceedAfterLogin() {
        if AuthService.biometricsAvailable() && !useFaceID {
            showFaceIDPrompt = true
        } else {
            currentScreen = .dashboard
        }
    }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = "Face ID no está configurado en este dispositivo."
            showError = true
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "Inicia sesión de forma segura en tu garaje.") { success, _ in
            DispatchQueue.main.async {
                if success {
                    viewModel.switchToUser(userID: currentUserID)
                    isLoggedIn = true
                    currentScreen = .dashboard
                } else {
                    errorMessage = "No se pudo reconocer tu rostro/huella."
                    showError = true
                }
            }
        }
    }
}

struct SocialLoginButton: View {
    let icon: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 55, height: 55)
                .background(Color(.secondarySystemBackground))
                .foregroundStyle(color)
                .clipShape(Circle())
        }
    }
}

struct SocialLoginTextButton: View {
    let text: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.title2)
                .fontWeight(.bold)
                .frame(width: 55, height: 55)
                .background(Color(.secondarySystemBackground))
                .foregroundStyle(color)
                .clipShape(Circle())
        }
    }
}

#Preview {
    LoginView(currentScreen: .constant(.login))
        .environmentObject(GarageViewModel())
}
