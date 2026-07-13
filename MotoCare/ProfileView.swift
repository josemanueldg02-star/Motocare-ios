//
//  ProfileView.swift
//  MotoCare
//
//  Antes esta pestaña era un simple Text placeholder. Ahora permite:
//  - ver/editar los datos de la moto (fuente única de verdad),
//  - activar/desactivar Face ID (solo si el dispositivo lo soporta),
//  - cerrar sesión de verdad.
//

import SwiftUI

struct ProfileView: View {
    @Binding var currentScreen: AppState
    @EnvironmentObject var viewModel: GarageViewModel

    @AppStorage("savedEmail") var savedEmail = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("useFaceID") var useFaceID = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuenta") {
                    LabeledContent("Correo", value: savedEmail.isEmpty ? "—" : savedEmail)
                }

                Section("Mi moto") {
                    TextField("Marca", text: $viewModel.motorcycle.make)
                    TextField("Modelo", text: $viewModel.motorcycle.model)
                    Stepper("Km: \(viewModel.motorcycle.mileage.formatted())",
                            value: $viewModel.motorcycle.mileage,
                            in: 0...1_000_000,
                            step: 100)
                    Stepper("Intervalo revisión: \(viewModel.motorcycle.serviceIntervalKm.formatted()) km",
                            value: $viewModel.motorcycle.serviceIntervalKm,
                            in: 1000...20000,
                            step: 500)
                }

                Section("Resumen") {
                    LabeledContent("Gasto total",
                                   value: viewModel.totalSpent.formatted(.currency(code: "EUR")))
                    LabeledContent("Próxima revisión",
                                   value: "\(viewModel.nextServiceMileage.formatted()) km")
                }

                Section("Seguridad") {
                    if AuthService.biometricsAvailable() {
                        Toggle("Entrar con Face ID", isOn: $useFaceID)
                    } else {
                        Text("Face ID no disponible en este dispositivo.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        logout()
                    } label: {
                        Text("Cerrar sesión")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Perfil")
        }
    }

    private func logout() {
        isLoggedIn = false
        // No borramos las credenciales del Keychain: el usuario podrá volver a entrar.
        withAnimation { currentScreen = .login }
    }
}

#Preview {
    ProfileView(currentScreen: .constant(.dashboard))
        .environmentObject(GarageViewModel())
}
