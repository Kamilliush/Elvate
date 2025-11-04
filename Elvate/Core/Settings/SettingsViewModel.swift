//
//  SettingsViewModel.swift
//  Elvate
//
//  Created by Kamil Jakut on 04/11/2025.
//

import Foundation
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
    
    func deleteAccount(currentPassword: String) async throws {
        let user = try AuthenticationManager.shared.getAuthenticatedUser()
        guard let email = user.email else {
            throw URLError(.badServerResponse)
        }
        // reauthenticate with current password
        try await AuthenticationManager.shared.reauthenticateUser(email: email, password: currentPassword)
        // delete after successful reauth
        try await AuthenticationManager.shared.delete()
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
