//
//  LoginView.swift
//  MotoCare
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @Binding var currentScreen: AppState
    @EnvironmentObject var viewModel: GarageViewModel

    @AppStorage("currentUserEmail") var currentUserEmail = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("useFaceID") var useFaceID = false

    @State private var emailInput = ""
    @State private var passwordInput = ""

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showFaceIDPrompt = false

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
                        Text("Iniciar Sesión")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }

                    // Face ID reentra en la ÚLTIMA cuenta usada, si el usuario lo activó.
                    if !currentUserEmail.isEmpty && useFaceID && AuthService.biometricsAvailable() {
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
                        SocialLoginButton(icon: "applelogo", color: .primary) { simulateSocialLogin(provider: "Apple") }
                        SocialLoginTextButton(text: "G", color: .red) { simulateSocialLogin(provider: "Google") }
                        SocialLoginButton(icon: "phone.fill", color: .green) { simulateSocialLogin(provider: "Teléfono") }
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
        }
    }

    // MARK: - Lógica

    private func loginWithEmail() {
        let email = AuthService.normalize(emailInput)

        guard AuthService.verify(email: email, password: passwordInput) else {
            errorMessage = "Correo o contraseña incorrectos."
            showError = true
            return
        }

        currentUserEmail = email
        viewModel.switchToUser(email: email) // carga los datos de ESTE usuario
        isLoggedIn = true
        proceedAfterLogin()
    }

    private func simulateSocialLogin(provider: String) {
        let socialEmail = "usuario@\(provider.lowercased()).com"
        if !AuthService.accountExists(email: socialEmail) {
            AuthService.register(email: socialEmail, password: UUID().uuidString)
        }
        currentUserEmail = AuthService.normalize(socialEmail)
        viewModel.switchToUser(email: currentUserEmail)
        isLoggedIn = true
        proceedAfterLogin()
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
                    viewModel.switchToUser(email: currentUserEmail)
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
