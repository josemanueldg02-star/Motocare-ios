//
//  RegisterView.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 11/07/2026.
//

import SwiftUI

struct RegisterView: View {
    // Recibe el "mando"
    @Binding var currentScreen: AppState
    
    @AppStorage("savedEmail") var savedEmail = ""
    @AppStorage("savedPassword") var savedPassword = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("useFaceID") var useFaceID = false
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showFaceIDPrompt = false
    
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
            
            Button(action: {
                validarRegistro()
            }) {
                Text("Registrarse")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
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
                        .foregroundColor(.gray)
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
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    func validarRegistro() {
        if name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "Por favor, rellena todos los campos."
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
        
        savedEmail = email
        savedPassword = password
        isLoggedIn = true
        
        showFaceIDPrompt = true // <- CAMBIADO
    }
    
    func simulateSocialLogin(provider: String) {
        savedEmail = "usuario@\(provider.lowercased()).com"
        savedPassword = "social_password_mock"
        isLoggedIn = true
        showFaceIDPrompt = true
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
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
                .foregroundColor(.gray)
                .frame(width: 20)
            SecureField(placeholder, text: $text)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    RegisterView(currentScreen: .constant(.login))
}
