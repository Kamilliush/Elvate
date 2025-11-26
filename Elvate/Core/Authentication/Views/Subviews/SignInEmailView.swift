//
//  SignInEmailView.swift
//  SignInEmailViewElvate
//
//  Created by Kamil Jakut on 01/11/2025.
//

import SwiftUI

struct SignInEmailView: View {
    
    @StateObject private var viewModel = SignInEmailViewModel()
    @Binding var showSingInView: Bool
    
    var body: some View {
        VStack {
            TextField("Email...", text: $viewModel.email)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)
            SecureField("Password...", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)
            
            Button {
                Task {
                    do {
                        try await viewModel.signUp()
                        showSingInView = false
                        return
                    } catch {
                        print("Error: \(error)")
                    }
                    
                    do {
                        try await viewModel.signIn()
                        showSingInView = false
                        return
                    } catch {
                        print("Error: \(error)")
                    }
                }
               
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign in with Email")
    }
}

#Preview {
    NavigationStack{
        SignInEmailView(showSingInView:  .constant(false))
    }
    
}
