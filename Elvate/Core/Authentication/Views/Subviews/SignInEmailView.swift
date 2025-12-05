//
//  SignInEmailView.swift
//

import SwiftUI
import FirebaseAuth

struct SignInEmailView: View {
    
    @StateObject private var viewModel = SignInEmailViewModel()
    @Binding var showSingInView: Bool
    
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // HEADER
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email sign-in")
                        .font(.largeTitle.bold())
                    Text("Use your email and password to continue.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // FORM CARD
                VStack(alignment: .leading, spacing: 14) {
                    
                    // EMAIL FIELD
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 10) {
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                            
                            TextField("name@example.com", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocorrectionDisabled()
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.primary.opacity(0.08))
                        )
                    }
                    
                    // PASSWORD FIELD
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 10) {
                            Image(systemName: "lock")
                                .foregroundStyle(.secondary)
                            
                            if isPasswordVisible {
                                TextField("Your password", text: $viewModel.password)
                                    .textContentType(.password)
                                    .foregroundColor(.primary)
                            } else {
                                SecureField("Your password", text: $viewModel.password)
                                    .textContentType(.password)
                                    .foregroundColor(.primary)
                            }
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isPasswordVisible.toggle()
                                }
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.primary.opacity(0.08))
                        )
                    }

                    // ERROR MESSAGE
                    if let errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                    }
                    
                    // BUTTON
                    Button {
                        Task { await signInOrSignUp() }
                    } label: {
                        HStack(spacing: 8) {
                            if isProcessing { ProgressView().tint(.white) }
                            Text(isProcessing ? "Please wait…" : "Continue")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    .disabled(isProcessing)
                    
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.primary.opacity(0.06))
                )
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                
                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .navigationTitle("Sign in with Email")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Validation helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        // Prosta walidacja formatu – wystarczy na UI (Firebase i tak zweryfikuje dokładniej)
        // Możesz użyć też NSDataDetector(.link) lub bardziej rozbudowanego regexu.
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.contains("@") && trimmed.contains(".")
    }
    
    // LOGIN + SIGNUP FALLBACK z walidacją i mapowaniem błędów
    private func signInOrSignUp() async {
        errorMessage = nil
        
        let email = viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = viewModel.password
        
        // UI validation
        guard !email.isEmpty else {
            errorMessage = "Email is required."
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Enter a valid email address."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Password is required."
            return
        }
        guard password.count >= 6 else {
            // Firebase standard: min 6 chars
            errorMessage = "Password must be at least 6 characters long."
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Najpierw spróbuj rejestracji
        do {
            try await viewModel.signUp()
            showSingInView = false
            return
        } catch {
            // jeżeli rejestracja się nie udała, sprawdź, czy to typowy przypadek "email already in use"
            if let authError = error as NSError?,
               let code = AuthErrorCode(rawValue: authError.code),
               code == .emailAlreadyInUse {
                // spróbuj zalogować
            } else {
                // inne błędy rejestracji – pokaż czytelny komunikat
                errorMessage = mapAuthError(error, context: .signUp)
                return
            }
        }
        
        // Potem spróbuj logowania
        do {
            try await viewModel.signIn()
            showSingInView = false
        } catch {
            errorMessage = mapAuthError(error, context: .signIn)
        }
    }
    
    // MARK: - Error mapping
    
    private enum AuthContext { case signIn, signUp }
    
    private func mapAuthError(_ error: Error, context: AuthContext) -> String {
        guard let err = error as NSError?,
              let code = AuthErrorCode(rawValue: err.code) else {
            return defaultMessage(for: context, underlying: error.localizedDescription)
        }
        
        switch code {
        case .invalidEmail:
            return "Enter a valid email address."
        case .emailAlreadyInUse:
            return "This email is already in use. Try signing in."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email."
        case .userDisabled:
            return "This account has been disabled."
        case .operationNotAllowed:
            return "This operation is not allowed."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        case .networkError:
            return "Network error. Check your internet connection."
        default:
            return defaultMessage(for: context, underlying: err.localizedDescription)
        }
    }
    
    private func defaultMessage(for context: AuthContext, underlying: String) -> String {
        switch context {
        case .signIn:
            return "Could not sign in: \(underlying)"
        case .signUp:
            return "Could not sign up: \(underlying)"
        }
    }
}

