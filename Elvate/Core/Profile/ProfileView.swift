//
//  ProfileView.swift
//  Elvate
//
//  Created by Kamil Jakut on 04/11/2025.
//

import SwiftUI
import Combine
import Charts

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published private(set) var user: DBUser? = nil
    @Published var completed: [DBCompletedWorkout] = []
    
    // Historia wagi do wykresu
    @Published var weightHistory: [DBMetricEntry] = []
    @Published var isLoadingWeight: Bool = false
    @Published var weightError: String? = nil
    
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
    }
    
    func loadCompletedWorkouts() async {
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else { return }
        do {
            let items = try await CompletedWorkoutsManager.shared.fetchCompleted(userId: auth.uid)
            self.completed = items
        } catch {
            print("Fetch completed workouts failed:", error)
        }
    }
    
    func loadWeightHistory() async {
        weightError = nil
        isLoadingWeight = true
        defer { isLoadingWeight = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            weightError = "Brak zalogowanego użytkownika."
            return
        }
        do {
            // pobierz całą historię wagi (lub limit, jeśli chcesz)
            let items = try await MeasurementsManager.shared.fetchMetricEntries(
                userId: auth.uid,
                metricId: MeasurementMetric.weight.metricId
            )
            self.weightHistory = items
        } catch {
            weightError = "Nie udało się pobrać historii wagi: \(error.localizedDescription)"
        }
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
            
            // Wykres historii wagi
            Section(header: Text("Waga – historia")) {
                if viewModel.isLoadingWeight {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let err = viewModel.weightError {
                    VStack(spacing: 8) {
                        Text(err)
                            .foregroundStyle(.red)
                        Button("Spróbuj ponownie") {
                            Task { await viewModel.loadWeightHistory() }
                        }
                    }
                } else if viewModel.weightHistory.isEmpty {
                    Text("Brak danych o wadze")
                        .foregroundStyle(.secondary)
                } else {
                    Chart {
                        ForEach(viewModel.weightHistory, id: \.id) { e in
                            LineMark(
                                x: .value("Data", e.dateCreated),
                                y: .value("Waga (kg)", e.value)
                            )
                            PointMark(
                                x: .value("Data", e.dateCreated),
                                y: .value("Waga (kg)", e.value)
                            )
                        }
                    }
                    .frame(height: 220)
                  
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
            
            // Zakończone treningi
            Section(header: Text("Zakończone treningi")) {
                if viewModel.completed.isEmpty {
                    Text("Brak zakończonych treningów")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.completed, id: \.id) { w in
                        NavigationLink {
                            CompletedWorkoutDetailView(workout: w)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(w.routineName)
                                    .font(.headline)
                                HStack {
                                    Text(w.dateCompleted.formatted(date: .abbreviated, time: .shortened))
                                    Spacer()
                                    Text(timeString(w.durationSeconds))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .task {
            try? await viewModel.loadCurrentUser()
            await viewModel.loadCompletedWorkouts()
            await viewModel.loadWeightHistory()
        }
        .navigationTitle("Profile")
    }
    
    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
