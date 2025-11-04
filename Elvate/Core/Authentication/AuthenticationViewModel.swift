//
//  AuthenticationViewModel.swift
//  Elvate
//
//  Created by Kamil Jakut on 04/11/2025.
//

import Foundation
import Combine

@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    func signInGoogle() async throws{
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        let authDataResult = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        try await UserManager.shared.createNewUser(auth: authDataResult)
    }
}
