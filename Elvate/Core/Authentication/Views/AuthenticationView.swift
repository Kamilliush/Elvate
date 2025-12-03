//
//  AuthenticationView.swift
//  Elvate
//
//  Created by Kamil Jakut on 01/11/2025.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct AuthenticationView: View {
    
    @StateObject private var viewModel: AuthenticationViewModel
    @Binding var showSingInView: Bool
    
    @State private var isSigningInGoogle: Bool = false
    @State private var errorMessage: String? = nil
    
    init(showSingInView: Binding<Bool>) {
        _showSingInView = showSingInView
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Nagłówek
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome")
                        .font(.largeTitle.bold())
                    Text("Sign in to continue to your workouts and progress.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Karta akcji logowania
                VStack(spacing: 14) {
                    NavigationLink{
                        SignInEmailView(showSingInView: $showSingInView)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                            Text("Sign in with email")
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    
                    VStack(spacing: 10) {
                        GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .light, style: .wide, state: .normal)) {
                            Task {
                                await signInWithGoogle()
                            }
                        }
                        .disabled(isSigningInGoogle)
                        
                        if isSigningInGoogle {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Signing in with Google…")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
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
                
                if let errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func signInWithGoogle() async {
        errorMessage = nil
        isSigningInGoogle = true
        defer { isSigningInGoogle = false }
        do {
            try await viewModel.signInGoogle()
            showSingInView = false
        } catch {
            errorMessage = "Google sign-in failed: \(error.localizedDescription)"
        }
    }
}

