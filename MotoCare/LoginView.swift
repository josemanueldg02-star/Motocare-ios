//
//  LoginView.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 11/07/2026.
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @Binding var currentScreen: AppState
    
    // Variables guardadas en el disco duro
    @AppStorage("savedEmail") var savedEmail = ""
    @AppStorage("savedPassword") var savedPassword = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("useFaceID") var useFaceID = false
    
    @State private var emailInput = ""
    @State private var passwordInput = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showFaceIDPrompt = false // Para preguntar por FaceID
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Spacer()
                
                Image(systemName: "motorcycle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("Bienvenido a Motocare")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Tu Taller Virtual en el bolsillo")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                VStack(spacing: 15) {
                    CustomTextField(icon: "envelope.fill", placeholder: "Correo electrónico", text: $emailInput)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    CustomSecureField(icon: "lock.fill", placeholder: "Contraseña", text: $passwordInput)
                    
                    // Botón de Iniciar Sesión Normal
                    Button(action: loginWithEmail) {
                        Text("Iniciar Sesión")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    // Botón Face ID (Solo aparece si ya hay un usuario registrado en el móvil)
                    if !savedEmail.isEmpty {
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
                            .foregroundColor(.white)
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
                
                Spacer()
                
                NavigationLink(destination: RegisterView(currentScreen: $currentScreen)) {
                    Text("¿No tienes cuenta? **Regístrate**")
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .alert("Error de Inicio", isPresented: $showError) {
                Button("Entendido", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            // <- NUEVA ALERTA: Pregunta por Face ID tras login exitoso
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
                Text("Has iniciado sesión correctamente. ¿Quieres usar Face ID para entrar automáticamente la próxima vez?")
            }
        }
    }
    
    // ==========================================
    //        LÓGICA DE INICIO DE SESIÓN
    // ==========================================
    
    func loginWithEmail() {
        if emailInput == savedEmail && passwordInput == savedPassword && !savedEmail.isEmpty {
            isLoggedIn = true
            // En vez de ir directo al dashboard, preguntamos por FaceID si no lo tiene activo
            if !useFaceID {
                showFaceIDPrompt = true
            } else {
                currentScreen = .dashboard
            }
        } else {
            errorMessage = "Correo o contraseña incorrectos."
            showError = true
        }
    }
    
    func simulateSocialLogin(provider: String) {
        savedEmail = "usuario@\(provider.lowercased()).com"
        savedPassword = "social_password_mock"
        isLoggedIn = true
        if !useFaceID {
            showFaceIDPrompt = true
        } else {
            currentScreen = .dashboard
        }
    }
    
    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        // Verificamos si el iPhone tiene FaceID habilitado
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Inicia sesión de forma segura en tu garaje."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        isLoggedIn = true
                        currentScreen = .dashboard
                    } else {
                        errorMessage = "No se pudo reconocer tu rostro/huella."
                        showError = true
                    }
                }
            }
        } else {
            errorMessage = "Face ID no está configurado en este dispositivo."
            showError = true
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
                .background(Color(UIColor.secondarySystemBackground))
                .foregroundColor(color)
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
                .background(Color(UIColor.secondarySystemBackground))
                .foregroundColor(color)
                .clipShape(Circle())
        }
    }
}
