//
//  RegisterView.swift
//  MotoCare
//

import SwiftUI

struct RegisterView: View {
    @Binding var currentScreen: AppState
    @EnvironmentObject var viewModel: GarageViewModel

    @AppStorage("currentUserID") var currentUserID = ""
    @AppStorage("currentUserDisplay") var currentUserDisplay = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("useFaceID") var useFaceID = false

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var appleCoordinator = AppleSignInCoordinator()

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showFaceIDPrompt = false
    @State private var showPhoneAuth = false

    var body: some View {
        VStack {
            Text("Crear Cuenta")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .padding(.bottom, 20)

            VStack(spacing: 15) {
                CustomTextField(icon: "person.fill", placeholder: "Nombre completo", text: $name)

                CustomTextField(icon: "envelope.fill", placeholder: "Correo electrónico", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                CustomSecureField(icon: "lock.fill", placeholder: "Contraseña", text: $password)
                CustomSecureField(icon: "lock.fill", placeholder: "Confirmar Contraseña", text: $confirmPassword)
            }
            .padding(.horizontal, 20)

            Button(action: validarRegistro) {
                ZStack {
                    Text("Registrarse")
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
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .alert("Error", isPresented: $showError) {
                Button("Entendido", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("¡Registro Exitoso!", isPresented: $showFaceIDPrompt) {
                Button("Sí, activar Face ID") {
                    useFaceID = true
                    currentScreen = .dashboard
                }
                Button("No, gracias", role: .cancel) {
                    useFaceID = false
                    currentScreen = .dashboard
                }
            } message: {
                Text("Tu cuenta ha sido creada. ¿Quieres usar Face ID para entrar más rápido la próxima vez?")
            }

            VStack(spacing: 15) {
                HStack {
                    VStack { Divider() }
                    Text("O regístrate con")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    VStack { Divider() }
                }
                .padding(.vertical, 5)

                HStack(spacing: 25) {
                    SocialLoginButton(icon: "applelogo", color: .primary) { registerWithApple() }
                    SocialLoginTextButton(text: "G", color: .red) { registerWithGoogle() }
                    SocialLoginButton(icon: "phone.fill", color: .green) { showPhoneAuth = true }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            Spacer()
        }
        .sheet(isPresented: $showPhoneAuth) {
            PhoneAuthView { user in
                applyRegistration(user)
            }
        }
    }

    private func validarRegistro() {
        let cleanEmail = AuthService.normalize(email)

        if name.isEmpty || cleanEmail.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "Por favor, rellena todos los campos."
            showError = true
            return
        }
        if !cleanEmail.contains("@") || !cleanEmail.contains(".") {
            errorMessage = "Introduce un correo válido."
            showError = true
            return
        }
        if password.count < 6 {
            errorMessage = "La contraseña debe tener al menos 6 caracteres."
            showError = true
            return
        }
        if password != confirmPassword {
            errorMessage = "Las contraseñas no coinciden."
            showError = true
            return
        }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let user = try await AuthService.register(name: name, email: cleanEmail, password: password)
                applyRegistration(user)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func registerWithGoogle() {
        guard let rootVC = SocialAuthHelpers.rootViewController else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let user = try await AuthService.signInWithGoogle(presenting: rootVC)
                applyRegistration(user)
            } catch is CancellationError {
                // El usuario canceló el diálogo de Google; no mostramos error.
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func registerWithApple() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let result = try await appleCoordinator.signIn()
                let user = try await AuthService.signInWithApple(idToken: result.idToken, rawNonce: result.rawNonce, fullName: result.fullName)
                applyRegistration(user)
            } catch is CancellationError {
                // El usuario canceló el diálogo de Apple; no mostramos error.
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Aplica el resultado de cualquier método de registro (email, Google, Apple o teléfono).
    private func applyRegistration(_ user: AppUser) {
        currentUserID = user.uid
        currentUserDisplay = user.displayIdentifier
        viewModel.switchToUser(userID: user.uid) // usuario nuevo => garaje vacío, sin moto mock
        isLoggedIn = true

        if AuthService.biometricsAvailable() {
            showFaceIDPrompt = true
        } else {
            currentScreen = .dashboard
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.gray)
                .frame(width: 20)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.gray)
                .frame(width: 20)
            SecureField(placeholder, text: $text)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    RegisterView(currentScreen: .constant(.login))
        .environmentObject(GarageViewModel())
}
