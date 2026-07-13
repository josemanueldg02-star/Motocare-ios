//
//  ProfileView.swift
//  MotoCare
//

import SwiftUI

struct ProfileView: View {
    @Binding var currentScreen: AppState
    @EnvironmentObject var viewModel: GarageViewModel

    @AppStorage("currentUserEmail") var currentUserEmail = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("useFaceID") var useFaceID = false

    @State private var showEditBike = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuenta") {
                    LabeledContent("Correo", value: currentUserEmail.isEmpty ? "—" : currentUserEmail)
                }

                Section("Mi moto") {
                    if let bike = viewModel.motorcycle {
                        LabeledContent("Moto", value: "\(bike.make) \(bike.model)")
                        LabeledContent("Kilometraje", value: "\(bike.mileage.formatted()) km")
                        LabeledContent("Intervalo revisión", value: "\(bike.serviceIntervalKm.formatted()) km")
                        Button("Editar moto") { showEditBike = true }
                    } else {
                        Button("Añadir moto") { showEditBike = true }
                    }
                }

                Section("Resumen") {
                    LabeledContent("Gasto total",
                                   value: viewModel.totalSpent.formatted(.currency(code: "EUR")))
                    if let next = viewModel.nextServiceMileage {
                        LabeledContent("Próxima revisión", value: "\(next.formatted()) km")
                    }
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
            .sheet(isPresented: $showEditBike) {
                AddBikeView(existing: viewModel.motorcycle)
                    .environmentObject(viewModel)
            }
        }
    }

    private func logout() {
        isLoggedIn = false
        currentUserEmail = ""
        viewModel.switchToUser(email: nil) // descarga los datos del usuario en memoria
        withAnimation { currentScreen = .login }
    }
}

#Preview {
    ProfileView(currentScreen: .constant(.dashboard))
        .environmentObject(GarageViewModel())
}
