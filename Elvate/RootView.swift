//
//  RootView.swift
//  Elvate
//
//  Created by Kamil Jakut on 01/11/2025.
//

import SwiftUI

struct RootView: View {
    
    @State private var showSignInView: Bool = false
    @State private var selectedTab: Tab = .workout
    
    enum Tab {
        case workout
        case profile
        case settings
    }
    
    var body: some View {
        ZStack {
            if !showSignInView {
                TabView(selection: $selectedTab) {
                    
                    NavigationStack {
                        WorkoutView()
                            .navigationTitle("Workout")
                    }
                    .tabItem {
                        Image(systemName: "figure.strengthtraining.traditional")
                        Text("Workout")
                    }
                    .tag(Tab.workout)
                    
                    NavigationStack {
                        ProfileView(showSignInView: $showSignInView)
                            .navigationTitle("Profile")
                    }
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Profile")
                    }
                    .tag(Tab.profile)
                    
                    NavigationStack{
                        SettingsView(showSignInView: $showSignInView)
                            .navigationTitle("Settings")
                    }
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(Tab.settings)
                    
                }
            }
        }
        .onAppear {
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
            self.showSignInView = authUser == nil
        }
        .fullScreenCover(isPresented: $showSignInView) {
            NavigationStack {
                AuthenticationView(showSingInView: $showSignInView)
            }
        }
    }
}

#Preview {
    RootView()
        
}

