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
    
    init(showSingInView: Binding<Bool>) {
        _showSingInView = showSingInView
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel())
    }
    
    var body: some View {
        
        VStack {
            NavigationLink{
                SignInEmailView(showSingInView: $showSingInView)
            } label: {
                Text("Sign in with email")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                Task {
                    do {
                        try await viewModel.signInGoogle()
                        showSingInView = false
                    } catch {
                        print(error)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign In")
    }
}
