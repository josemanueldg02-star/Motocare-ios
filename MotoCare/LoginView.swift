//
//  LoginView.swift
//  MotoCare
//
//  Created by Jose Manuel Dominguez Garcia on 11/07/2026.
//

import SwiftUI

struct LoginView: View {
    // Recibe el "mando" para cambiar de pantalla
    @Binding var currentScreen: AppState
    
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
                    .padding(.bottom, 30)
                
                // Botones
                VStack(spacing: 15) {
                    LoginButtonView(icon: "applelogo", title: "Continuar con Apple", backgroundColor: .black, textColor: .white) {
                        currentScreen = .dashboard // Cambia al panel principal
                    }
                    
                    LoginButtonView(icon: "network", title: "Continuar con Google", backgroundColor: .white, textColor: .black, hasBorder: true) {
                        currentScreen = .dashboard // Cambia al panel principal
                    }
                    
                    // Va a la ventana de registro
                    NavigationLink(destination: RegisterView(currentScreen: $currentScreen)) {
                        LoginButtonView(icon: "envelope.fill", title: "Continuar con Email", backgroundColor: .blue, textColor: .white) {
                            // Vacío porque NavigationLink ya hace la navegación
                        }
                    }
                    
                    LoginButtonView(icon: "phone.fill", title: "Continuar con Nº de Teléfono", backgroundColor: .green, textColor: .white) {
                        currentScreen = .dashboard // Cambia al panel principal
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Va a la ventana de registro
                NavigationLink(destination: RegisterView(currentScreen: $currentScreen)) {
                    Text("¿No tienes cuenta? **Regístrate**")
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// Subvista del botón (Acepta acciones)
struct LoginButtonView: View {
    let icon: String
    let title: String
    let backgroundColor: Color
    let textColor: Color
    var hasBorder: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasBorder ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview {
    LoginView(currentScreen: .constant(.login))
}
