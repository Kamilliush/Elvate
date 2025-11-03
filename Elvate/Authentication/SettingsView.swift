//
//  SettingsView.swift
//  Elvate
//
//  Created by Kamil Jakut on 01/11/2025.
//

import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    
    @Published var authPrioviders: [AuthProviderOption] = []
    
    func loadAuthProviders() {
        if let provider = try? AuthenticationManager.shared.getProviders() {
            authPrioviders = provider
        }
    }
    
    func logOut() throws {
        try AuthenticationManager.shared.signOut()
    }
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
    func updateEmail(newEmail: String, currentPassword: String) async throws {
        try await AuthenticationManager.shared.updateEmail(
            newEmail: newEmail,
            currentPassword: currentPassword
        )
    }

    func updatePassword(currentPassword: String, newPassword: String) async throws {
        let user = try AuthenticationManager.shared.getAuthenticatedUser()
        guard let email = user.email else {
            throw URLError(.badServerResponse)
        }
        try await AuthenticationManager.shared.reauthenticateUser(email: email, password: currentPassword)
        try await AuthenticationManager.shared.updatePassword(password: newPassword)
    }
    
}
struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    
    // popupy
    @State private var showUpdateEmailPopup = false
    @State private var showUpdatePasswordPopup = false
    
    // dane do popupów
    @State private var newEmail = ""
    @State private var currentEmailPassword = ""
    
    @State private var newPassword = ""
    @State private var currentPassword = ""
    
    var body: some View {
        List {
            Button("Log out") {
                Task {
                    do {
                        try viewModel.logOut()
                        showSignInView = true
                    } catch {
                        print(error)
                    }
                }
            }
            
            if viewModel.authPrioviders.contains(.email) {
                emailSection
            }
        }
        .onAppear {
            viewModel.loadAuthProviders()
        }
        .navigationBarTitle("Settings")
        .alert("Zmień e-mail", isPresented: $showUpdateEmailPopup) {
            TextField("Nowy e-mail", text: $newEmail)
            SecureField("Aktualne hasło", text: $currentPassword)
            
            Button("Anuluj", role: .cancel) {}
            Button("Zapisz") {
                Task {
                    do {
                        try await viewModel.updateEmail(newEmail: newEmail, currentPassword: currentPassword)
                        print("📩 Link weryfikacyjny wysłany na \(newEmail)")
                    } catch {
                        print("⚠️ Błąd: \(error.localizedDescription)")
                    }
                }
            }
        } message: {
            Text("Podaj nowy e-mail oraz aktualne hasło, aby wysłać link weryfikacyjny.")
        }
        .alert("Zmień hasło", isPresented: $showUpdatePasswordPopup) {
            SecureField("Aktualne hasło", text: $currentPassword)
            SecureField("Nowe hasło", text: $newPassword)
            
            Button("Anuluj", role: .cancel) {}
            Button("Zapisz") {
                Task {
                    do {
                        try await viewModel.updatePassword(
                            currentPassword: currentPassword,
                            newPassword: newPassword
                        )
                        print("✅ Hasło zostało zmienione!")
                    } catch {
                        print("⚠️ Błąd: \(error.localizedDescription)")
                    }
                }
            }
        } message: {
            Text("Podaj aktualne i nowe hasło, aby zaktualizować dane logowania.")
        }
    }
}


#Preview {
    NavigationStack{
        SettingsView(showSignInView: .constant(false))
    }
}

extension SettingsView {
    private var emailSection: some View {
        Section {
            Button("Set reset Password link") {
                Task {
                    do {
                        try await viewModel.resetPassword()
                        print("Password reset!")
                    } catch {
                        print(error)
                    }
                }
            }
            
            Button("Update Password") {
                showUpdatePasswordPopup = true
            }
            
            Button("Update email") {
                showUpdateEmailPopup = true
            }
        } header: {
            Text("Email Functions")
        }

    }
}
