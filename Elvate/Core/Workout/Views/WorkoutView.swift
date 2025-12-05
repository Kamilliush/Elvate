//
//  WorkoutView.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import SwiftUI
import Combine

struct WorkoutView: View {
    @EnvironmentObject private var routineStore: RoutineStore
    @State private var path = NavigationPath()
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    @State private var editTarget: Routine? = nil
    @State private var showEditSheet: Bool = false
    
    // Deletion
    @State private var deleteTarget: Routine? = nil
    @State private var showDeleteConfirm: Bool = false
    @State private var deleteErrorMessage: String? = nil
    @State private var isDeleting: Bool = false
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Workouts")
                            .font(.largeTitle.bold())
                        Text("Create and manage your training routines.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // New routine button
                    NavigationLink {
                        ExercisesView(selectionMode: true) { selected in
                            path.append(NavDestination.personalize(selected))
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("New routine")
                                    .font(.headline)
                                Text("Pick exercises and personalize sets")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    
                    // List content
                    Group {
                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading saved routines…")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else if let errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Error: \(errorMessage)")
                                    .foregroundStyle(.secondary)
                                Button {
                                    Task { await loadRemoteRoutines() }
                                } label: {
                                    Text("Try again")
                                        .font(.headline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else if routineStore.routines.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "list.bullet.rectangle.portrait")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text("No routines yet")
                                    .font(.headline)
                                Text("Tap “New routine” to create your first plan.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Saved routines")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                
                                ForEach(routineStore.routines) { routine in
                                    NavigationLink {
                                        RoutineDetailView(routine: routine)
                                    } label: {
                                        RoutineRow(routine: routine, inProgress: isInProgress(routineName: routine.name))
                                    }
                                    .contextMenu {
                                        Button {
                                            editTarget = routine
                                            showEditSheet = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            deleteTarget = routine
                                            showDeleteConfirm = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            editTarget = routine
                                            showEditSheet = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTarget = routine
                                            showDeleteConfirm = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: NavDestination.self) { destination in
                switch destination {
                case .personalize(let exercises):
                    PersonalizeRoutineView(exercises: exercises)
                        .environmentObject(routineStore)
                }
            }
            .task {
                await loadRemoteRoutines()
            }
            .refreshable {
                await loadRemoteRoutines()
            }
            .sheet(isPresented: $showEditSheet) {
                if let editTarget {
                    EditRoutineView(routine: editTarget) { updated in
                        routineStore.update(updated)
                    }
                }
            }
            .alert(deleteConfirmationTitle, isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    Task { await performDelete() }
                }
                Button("Cancel", role: .cancel) {
                }
            } message: {
                if let deleteTarget {
                    Text("Are you sure you want to delete “\(deleteTarget.name)”? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this routine? This action cannot be undone.")
                }
            }
            .alert("Delete failed", isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage ?? "")
            }
        }
    }
    
    private var deleteConfirmationTitle: String {
        if let t = deleteTarget {
            return "Delete “\(t.name)”?"
        }
        return "Delete routine?"
    }
    
    // MARK: - In-progress flag
    
    private func isInProgress(routineName: String) -> Bool {
        WorkoutInProgressStore.shared.load(routineName: routineName) != nil
    }
    
    // MARK: - Remote load
    
    private func loadRemoteRoutines() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "User not logged in."
            return
        }
        
        do {
            let dbRoutines = try await RoutineManager.shared.fetchRoutines(userId: auth.uid)
            let uiRoutines: [Routine] = dbRoutines.map { db in
                let items: [ExerciseInRoutine] = db.items.map { ex in
                    let exModel = Exercise(
                        id: ex.exerciseId,
                        name: ex.exerciseName,
                        force: nil,
                        level: nil,
                        mechanic: nil,
                        equipment: nil,
                        primaryMuscles: [],
                        secondaryMuscles: [],
                        instructions: [],
                        category: "",
                        images: []
                    )
                    let plan = ex.plan.map { SetPlan(reps: $0.reps, weight: $0.weight) }
                    return ExerciseInRoutine(exercise: exModel, plan: plan, restSeconds: ex.restSeconds)
                }
                var r = Routine(dbId: db.id, name: db.name, items: items, dateCreated: db.dateCreated)
                r.iconName = db.iconName ?? "figure.strengthtraining.traditional"
                return r
            }
            routineStore.routines = uiRoutines
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete
    
    private func performDelete() async {
        guard let target = deleteTarget else { return }
        deleteErrorMessage = nil
        
        guard let dbId = target.dbId else {
            await MainActor.run {
                routineStore.routines.removeAll { $0.id == target.id }
                showDeleteConfirm = false
                deleteTarget = nil
            }
            return
        }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            await MainActor.run {
                deleteErrorMessage = "User not logged in."
            }
            return
        }
        
        do {
            try await RoutineManager.shared.deleteRoutine(userId: auth.uid, routineId: dbId)
            await MainActor.run {
                routineStore.remove(byDbId: dbId)
                showDeleteConfirm = false
                deleteTarget = nil
            }
        } catch {
            await MainActor.run {
                deleteErrorMessage = "Failed to delete routine: \(error.localizedDescription)"
            }
        }
    }
}

private enum NavDestination: Hashable {
    case personalize([Exercise])
}

private struct RoutineRow: View {
    let routine: Routine
    let inProgress: Bool
    
    var body: some View {
        let tint = iconTint(for: routine.iconName)
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.12))
                Image(systemName: routine.iconName)
                    .foregroundStyle(tint)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(routine.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if inProgress {
                        Text("In progress")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
                Text("\(routine.items.count) exercises")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

#Preview {
    WorkoutView()
        .environmentObject(RoutineStore())
}

