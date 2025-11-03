//
//  RootView.swift
//  Elvate
//
//  Created by Kamil Jakut on 01/11/2025.
//

import SwiftUI

struct RootView: View {
    
    @State private var showSingInView: Bool = false
    
    var body: some View {
        ZStack {
            if !showSingInView {
                NavigationStack {
                    SettingsView(showSignInView: $showSingInView)
                }
            }
        }
        .onAppear {
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
            self.showSingInView = authUser == nil
        }
        .fullScreenCover(isPresented: $showSingInView) {
            NavigationStack {
                AuthenticationView(showSingInView: $showSingInView)
            }
        }
    }
}

#Preview {
    RootView()
}
