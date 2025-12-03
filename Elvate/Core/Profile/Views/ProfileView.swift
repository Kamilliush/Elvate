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
    @EnvironmentObject private var routineStore: RoutineStore
    
    // Prosty stan błędu/usuwania
    @State private var deleteErrorMessage: String? = nil
    @State private var deletingIds: Set<String> = []
    
    let preferenceOptions: [String] = ["Sports", "Movies", "Books"]
    
    private func preferenceIsSelected( text: String) -> Bool {
        viewModel.user?.preferences?.contains(text) == true
    }
    
    // MARK: - Header helpers
    
    private var userInitials: String {
        if let email = viewModel.user?.email, let first = email.first {
            return String(first).uppercased()
        }
        return "U"
    }
    
    private var isPremium: Bool {
        viewModel.user?.isPremium ?? false
    }
    
    private var userEmail: String {
        viewModel.user?.email ?? "Unknown"
    }
    
    private var avatarURL: URL? {
        guard let urlString = viewModel.user?.photoUrl, let url = URL(string: urlString) else { return nil }
        return url
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                weightCard
                finishedWorkoutsCard
                measurementsShortcutCard
            }
            .padding(20)
        }
        .task {
            try? await viewModel.loadCurrentUser()
            await viewModel.loadCompletedWorkouts()
            await viewModel.loadWeightHistory()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Nie udało się usunąć treningu", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }
    
    // MARK: - Sections
    
    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                avatarView
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("User")
                            .font(.headline)
                        if isPremium {
                            Label("Premium", systemImage: "star.fill")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.yellow.opacity(0.2))
                                .foregroundColor(.yellow)
                                .clipShape(Capsule())
                                .accessibilityLabel("Premium account")
                        }
                    }
                    Text(userEmail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 10) {
                NavigationLink {
                    MeasurementsView()
                } label: {
                    Label("Measurements", systemImage: "ruler")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }
                // Usunięto przycisk Enable/Disable Premium zgodnie z prośbą
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.25),
                    Color.blue.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.15))
        )
    }
    
    private var avatarView: some View {
        Group {
            if let url = avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Circle().fill(Color.gray.opacity(0.2))
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderAvatar
                    @unknown default:
                        placeholderAvatar
                    }
                }
                .clipShape(Circle())
            } else {
                placeholderAvatar
            }
        }
    }
    
    private var placeholderAvatar: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.15))
            Text(userInitials)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.blue)
        }
    }
    
    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Weight", systemImage: "scalemass")
                    .font(.headline)
                Spacer()
                if let last = viewModel.weightHistory.last?.value {
                    let delta = weightDelta()
                    HStack(spacing: 6) {
                        Text(String(format: "%.1f kg", last))
                            .font(.subheadline.weight(.semibold))
                        if let delta {
                            let up = delta > 0
                            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                                .foregroundStyle(up ? .red : .green)
                            Text(String(format: "%+.1f", delta))
                                .foregroundStyle(up ? .red : .green)
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Last weight \(String(format: "%.1f", last)) kilograms")
                }
            }
            
            Group {
                if viewModel.isLoadingWeight {
                    HStack {
                        ProgressView()
                        Text("Loading weight history…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                } else if let err = viewModel.weightError {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(err).foregroundStyle(.secondary)
                        }
                        Button {
                            Task { await viewModel.loadWeightHistory() }
                        } label: {
                            Text("Try again")
                                .font(.headline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else if viewModel.weightHistory.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "scalemass")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("No weight data")
                            .font(.headline)
                        Text("Add your first measurement to see trends.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        NavigationLink {
                            MeasurementDetailView(metric: .weight)
                        } label: {
                            Text("Add measurement")
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    let values = viewModel.weightHistory.map { $0.value }
                    let minVal = values.min() ?? 0
                    let maxVal = values.max() ?? 0
                    let span = max(maxVal - minVal, 0)
                    let padding = max(span * 0.1, 0.5)
                    let lower = (span == 0) ? (minVal - 0.5) : (minVal - padding)
                    let upper = (span == 0) ? (maxVal + 0.5) : (maxVal + padding)
                    
                    Chart {
                        ForEach(viewModel.weightHistory, id: \.id) { e in
                            // Ostry wykres: bez interpolacji i bez AreaMark
                            LineMark(
                                x: .value("Date", e.dateCreated),
                                y: .value("Weight (kg)", e.value)
                            )
                            .foregroundStyle(.blue)
                            
                            PointMark(
                                x: .value("Date", e.dateCreated),
                                y: .value("Weight (kg)", e.value)
                            )
                            .symbolSize(20)
                            .foregroundStyle(.blue)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4))
                    }
                    .chartYScale(domain: lower...upper)
                    .frame(height: 220)
                }
            }
        }
        .padding(16)
        // Tło tylko dla karty (nie rozciąga się poza jej treść)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var finishedWorkoutsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Finished trainings", systemImage: "checkmark.circle")
                    .font(.headline)
                Spacer()
            }
            
            if viewModel.completed.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No finished trainings")
                            .font(.headline)
                        Text("Start a workout and it will appear here.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.completed.prefix(10), id: \.id) { w in
                        NavigationLink {
                            CompletedWorkoutDetailView(workout: w)
                        } label: {
                            workoutRow(w)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await deleteCompleted(workout: w) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .disabled(deletingIds.contains(w.id ?? ""))
                        }
                    }
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
    }
    
    private func workoutRow(_ w: DBCompletedWorkout) -> some View {
        // Priorytet: aktualna ikona z RoutineStore po routineId
        let liveIconName: String? = {
            if let rid = w.routineId, let r = routineStore.routines.first(where: { $0.dbId == rid }) {
                return r.iconName
            }
            return nil
        }()
        let icon = liveIconName ?? w.routineIconName ?? "figure.strengthtraining.traditional"
        let tint = iconTint(for: icon)
        return HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))
                Image(systemName: icon)
                    .foregroundStyle(tint)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(w.routineName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Text(w.dateCompleted.formatted(date: .abbreviated, time: .shortened))
                    Text("•")
                    Text(timeString(w.durationSeconds))
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var measurementsShortcutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Quick actions", systemImage: "bolt.fill")
                    .font(.headline)
                Spacer()
            }
            HStack(spacing: 12) {
                NavigationLink {
                    MeasurementDetailView(metric: .biceps)
                } label: {
                    quickActionButton(title: "Add biceps size", icon: "ruler", tint: .blue)
                }
                
                NavigationLink {
                    MeasurementDetailView(metric: .weight)
                } label: {
                    quickActionButton(title: "Add weight", icon: "scalemass", tint: .purple)
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
    }
    
    private func quickActionButton(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.15))
                Image(systemName: icon)
                    .foregroundStyle(tint)
            }
            .frame(width: 34, height: 34)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Utils
    
    private func weightDelta() -> Double? {
        let arr = viewModel.weightHistory
        guard arr.count >= 2, let last = arr.last?.value, let prev = arr.dropLast().last?.value else { return nil }
        return last - prev
    }
    
    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // MARK: - Delete action
    
    private func deleteCompleted(workout: DBCompletedWorkout) async {
        guard let docId = workout.id else {
            deleteErrorMessage = "Brak identyfikatora dokumentu."
            return
        }
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            deleteErrorMessage = "Brak zalogowanego użytkownika."
            return
        }
        await MainActor.run {
            deletingIds.insert(docId)
        }
        defer {
            Task { @MainActor in
                deletingIds.remove(docId)
            }
        }
        do {
            try await CompletedWorkoutsManager.shared.deleteCompletedWorkout(userId: auth.uid, documentId: docId)
            await MainActor.run {
                viewModel.completed.removeAll { $0.id == docId }
            }
        } catch {
            await MainActor.run {
                deleteErrorMessage = "Nie udało się usunąć: \(error.localizedDescription)"
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView(showSignInView: .constant(false))
                .environmentObject(RoutineStore())
        }
    }
}

