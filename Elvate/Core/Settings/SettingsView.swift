//
//  SettingsView.swift
//  Elvate
//
//  Created by Kamil Jakut on 01/11/2025.
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    
    // popupy
    @State private var showDeleteAccountPopup = false
    @State private var showUpdateEmailPopup = false
    @State private var showUpdatePasswordPopup = false
    
    // NOWE: potwierdzenie resetu hasła
    @State private var showResetConfirm = false
    
    // dane do popupów
    @State private var newEmail = ""
    @State private var currentEmailPassword = ""
    
    @State private var newPassword = ""
    @State private var currentPassword = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                accountCard
                if viewModel.authPrioviders.contains(.email) {
                    emailCard
                }
                helpCard
            }
            .padding(20)
        }
        .onAppear {
            viewModel.loadAuthProviders()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        
        // Delete account
        .alert("Delete Account", isPresented: $showDeleteAccountPopup) {
            SecureField("Current password", text: $currentPassword)
            
            Button("Cancel", role: .cancel) {
                currentPassword = ""
            }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteAccount(currentPassword: currentPassword)
                        currentPassword = ""
                        showDeleteAccountPopup = false
                        showSignInView = true
                    } catch {
                        print("Delete error: \(error.localizedDescription)")
                    }
                }
            }
        } message: {
            Text("To delete your account, please enter your current password.")
        }
        
        // Update email
        .alert("Change email", isPresented: $showUpdateEmailPopup) {
            TextField("New email", text: $newEmail)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            SecureField("Current password", text: $currentPassword)
            
            Button("Cancel", role: .cancel) {}
            Button("Send", role: .none) {
                Task {
                    do {
                        try await viewModel.updateEmail(newEmail: newEmail, currentPassword: currentPassword)
                        print("Verification link sent to \(newEmail)")
                    } catch {
                        print("Email update error: \(error.localizedDescription)")
                    }
                }
            }
        } message: {
            Text("Provide new email and your current password to send a verification link.")
        }
        
        // Update password
        .alert("Change password", isPresented: $showUpdatePasswordPopup) {
            SecureField("Current password", text: $currentPassword)
            SecureField("New password", text: $newPassword)
            
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                Task {
                    do {
                        try await viewModel.updatePassword(
                            currentPassword: currentPassword,
                            newPassword: newPassword
                        )
                        print("Password changed.")
                    } catch {
                        print("Password update error: \(error.localizedDescription)")
                    }
                }
            }
        } message: {
            Text("Enter your current and new password to update your credentials.")
        }
        
        // NOWE: Potwierdzenie wysłania maila z resetem hasła
        .alert("Send password reset link?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Send") {
                Task {
                    do {
                        try await viewModel.resetPassword()
                        print("Password reset email sent.")
                    } catch {
                        print("Reset error:", error.localizedDescription)
                    }
                }
            }
        } message: {
            Text("We will email you a link to reset your password.")
        }
    }
    
    // MARK: - Cards
    
    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Account", systemImage: "person.crop.circle")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 10) {
                Button {
                    Task {
                        do {
                            try viewModel.logOut()
                            showSignInView = true
                        } catch {
                            print("Logout error:", error.localizedDescription)
                        }
                    }
                } label: {
                    rowButton(title: "Log out", icon: "rectangle.portrait.and.arrow.right", tint: .blue)
                }
                
                Button(role: .destructive) {
                    showDeleteAccountPopup = true
                } label: {
                    rowButton(title: "Delete account", icon: "trash", tint: .red)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var emailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Email & Security", systemImage: "envelope")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 10) {
                Button {
                    // Zamiast od razu wysyłać – pokaż potwierdzenie
                    showResetConfirm = true
                } label: {
                    rowButton(title: "Send password reset link", icon: "envelope.badge", tint: .orange)
                }
                
                Button {
                    showUpdatePasswordPopup = true
                } label: {
                    rowButton(title: "Change password", icon: "key.fill", tint: .purple)
                }
                
                Button {
                    showUpdateEmailPopup = true
                } label: {
                    rowButton(title: "Change email", icon: "at", tint: .green)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var helpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Help", systemImage: "questionmark.circle")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 10) {
                Link(destination: URL(string: "https://support.apple.com/")!) {
                    rowButton(title: "Support", icon: "lifepreserver", tint: .blue)
                }
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    rowButton(title: "Privacy policy", icon: "hand.raised.fill", tint: .teal)
                }
                Link(destination: URL(string: "https://example.com/terms")!) {
                    rowButton(title: "Terms of service", icon: "doc.plaintext", tint: .gray)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Reusable row
    
    private func rowButton(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.15))
                Image(systemName: icon)
                    .foregroundStyle(tint)
            }
            .frame(width: 34, height: 34)
            
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack{
        SettingsView(showSignInView: .constant(false))
    }
}

