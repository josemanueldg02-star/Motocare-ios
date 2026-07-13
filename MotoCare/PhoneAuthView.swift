//
//  PhoneAuthView.swift
//  MotoCare
//
//  Flujo de login/registro por SMS en dos pasos: enviar código, verificarlo.
//  Sirve tanto para Login como para Registro: Firebase crea la cuenta sola
//  si el número no existía todavía.
//

import SwiftUI

struct PhoneAuthView: View {
    @Environment(\.dismiss) private var dismiss
    var onSuccess: (AppUser) -> Void

    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var verificationID: String?
    @State private var isLoading = false

    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "phone.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.green)
                    .padding(.top, 20)

                if verificationID == nil {
                    Text("Introduce tu número con el prefijo del país, por ejemplo +34 612 345 678.")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    CustomTextField(icon: "phone.fill", placeholder: "+34 600 000 000", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .padding(.horizontal, 20)

                    actionButton(title: "Enviar código", action: sendCode)
                } else {
                    Text("Te hemos enviado un código por SMS.")
                        .font(.footnote)
                        .foregroundStyle(.gray)

                    CustomTextField(icon: "lock.fill", placeholder: "Código de 6 dígitos", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 20)

                    actionButton(title: "Verificar", action: confirmCode)

                    Button("Usar otro número") {
                        verificationID = nil
                        verificationCode = ""
                    }
                    .font(.footnote)
                }

                Spacer()
            }
            .navigationTitle("Teléfono")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("Entendido", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    @ViewBuilder
    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.white)
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
    }

    private func sendCode() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                verificationID = try await AuthService.sendPhoneVerificationCode(phoneNumber: phoneNumber)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func confirmCode() {
        guard let verificationID else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let user = try await AuthService.confirmPhoneCode(verificationID: verificationID, code: verificationCode)
                onSuccess(user)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    PhoneAuthView(onSuccess: { _ in })
}
