//
//  ProfileView.swift
//  Elvate
//
//  Created by Kamil Jakut on 04/11/2025.
//

import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published private(set) var user: DBUser? = nil
    
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
    }
    
    func togglePremiumStatus() async throws {
        guard var user else { return }
        let currentValue = user.isPremium ?? false
        
        Task {
            try await UserManager.shared.updateUserPremiumStatus(userId: user.userId, isPremium: !currentValue)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }
    
    func addUserPreference(text: String) {
        guard let user else {return}
        
        Task {
            try await UserManager.shared.addUserPreference(userId: user.userId, preference: text)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }
    
    func removeUserPreference(text: String) {
        guard let user else {return}
        
        Task {
            try await UserManager.shared.removeUserPreference(userId: user.userId, preference: text)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }
}

struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    @Binding var showSignInView: Bool
    
    let preferenceOptions: [String] = ["Sports", "Movies", "Books"]
    
    private func preferenceIsSelected( text: String) -> Bool {
        viewModel.user?.preferences?.contains(text) == true
    }
    var body: some View {
        List {
            // Navigation to MeasurementsView
            Section {
                NavigationLink {
                    MeasurementsView()
                } label: {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundStyle(.blue)
                        Text("Measurements")
                            .font(.headline)
                    }
                }
            }
            
            if let user = viewModel.user {
                Text("userId: \(user.userId)")
                
                Button {
                    Task {
                        do {
                            try await viewModel.togglePremiumStatus()
                        } catch {
                            print("Toggle premium failed: \(error)")
                        }
                    }
                } label: {
                    Text ("User is premium: \((user.isPremium ?? false).description.capitalized)")
                }
                
                VStack{
                    
                    HStack {
                        ForEach(preferenceOptions, id: \.self) { string in
                            Button(string) {
                                if preferenceIsSelected(text: string) {
                                    viewModel.removeUserPreference(text: string)
                                } else {
                                    viewModel.addUserPreference(text: string)
                                }
                            }
                            .font(.headline)
                            .buttonStyle(.borderedProminent)
                            .tint(preferenceIsSelected(text: string) == true ? .green: .red)
                        }
                        
                        
                    }
                    
                    Text("user preferences: \((user.preferences ?? []).joined(separator: ", "))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .task {
            try? await viewModel.loadCurrentUser()
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink{
                    SettingsView(showSignInView: $showSignInView)
                } label: {
                    Image(systemName: "gear")
                        .font(.headline)
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
