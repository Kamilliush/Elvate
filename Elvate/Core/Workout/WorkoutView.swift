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
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 24) {
                Text("Twój trening")
                    .font(.largeTitle.bold())
                
                NavigationLink {
                    ExercisesView(selectionMode: true) { selected in
                        path.append(NavDestination.personalize(selected))
                    }
                } label: {
                    Text("New Routine")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                if isLoading {
                    ProgressView("Ładowanie zapisanych rutyn…")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let errorMessage {
                    VStack(spacing: 8) {
                        Text("Błąd: \(errorMessage)")
                            .foregroundStyle(.red)
                        Button("Spróbuj ponownie") {
                            Task { await loadRemoteRoutines() }
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else if routineStore.routines.isEmpty {
                    VStack(spacing: 8) {
                        Text("Brak zapisanych rutyn")
                            .foregroundStyle(.secondary)
                        Text("Utwórz pierwszą, klikając „New Routine”.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        Section(header: Text("Zapisane rutyny")) {
                            ForEach(routineStore.routines) { routine in
                                NavigationLink {
                                    RoutineDetailView(routine: routine)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(routine.name)
                                            .font(.headline)
                                        Text("\(routine.items.count) ćwicz.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Workout")
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
        }
    }
    
    // MARK: - Remote load
    
    private func loadRemoteRoutines() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "Brak zalogowanego użytkownika."
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
                return Routine(name: db.name, items: items, dateCreated: db.dateCreated)
            }
            // zasilamy lokalny store, żeby reszta UI działała jak dotąd
            routineStore.routines = uiRoutines
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum NavDestination: Hashable {
    case personalize([Exercise])
}

#Preview {
    WorkoutView()
        .environmentObject(RoutineStore())
}
