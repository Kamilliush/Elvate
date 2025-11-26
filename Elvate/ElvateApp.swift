//
//  ElvateApp.swift
//  Elvate
//
//  Created by Kamil Jakut on 01/11/2025.
//

import SwiftUI
import FirebaseCore
import Combine

@main
struct ElvateApp: App {
    @StateObject private var routineStore = RoutineStore()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationStack{
                RootView()
                    .environmentObject(routineStore)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        print("-----Firebase configured-----")
        return true
    }
}
