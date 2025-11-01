//
//  AuthenticationView.swift
//  Elvate
//
//  Created by Kamil Jakut on 01/11/2025.
//

import SwiftUI

@MainActor
struct AuthenticationView: View {
    
    @Binding var showSingInView: Bool
    
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
        }
        .padding()
        .navigationTitle("Sign In")
    }
}

#Preview {
    NavigationStack{
        AuthenticationView(showSingInView:  .constant(false))
    }
}
