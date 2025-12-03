//
//  SignInEmailView.swift
//

import SwiftUI

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
                                .foregroundColor(.primary)   // ← zapobiega niebieskiemu texowi
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
                    .disabled(isProcessing || viewModel.email.isEmpty || viewModel.password.isEmpty)
                    
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
    
    
    // LOGIN + SIGNUP FALLBACK
    private func signInOrSignUp() async {
        errorMessage = nil
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            try await viewModel.signUp()
            showSingInView = false
            return
        } catch { }
        
        do {
            try await viewModel.signIn()
            showSingInView = false
        } catch {
            errorMessage = "Could not sign in or sign up: \(error.localizedDescription)"
        }
    }
}
