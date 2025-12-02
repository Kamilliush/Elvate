import SwiftUI

struct RoutineDetailView: View {
    let routine: Routine
    
    @State private var states: [RuntimeExerciseState] = []
    
    // Tryb: podgląd vs. trening
    @State private var isRunning: Bool = false
    @State private var workoutElapsedSeconds: Int = 0
    @State private var workoutTimerTask: Task<Void, Never>? = nil
    @State private var errorMessage: String? = nil
    @State private var saveSuccess: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // Sheet podsumowania
    @State private var showSummary: Bool = false
    @State private var summary: WorkoutSummary? = nil
    
    // Wznawianie
    @State private var askResume: Bool = false
    
    // Edit
    @State private var showEdit: Bool = false
    @EnvironmentObject private var routineStore: RoutineStore
    
    // Lokalna kopia modelu do UI (aktualizowana z RoutineStore)
    @State private var currentRoutine: Routine
    
    init(routine: Routine) {
        self.routine = routine
        _currentRoutine = State(initialValue: routine)
    }
    
    var body: some View {
        List {
            headerSection
            
            ForEach($states) { $state in
                Section(header: Text(state.item.exercise.name)) {
                    if !isRunning {
                        // PODGLĄD
                        ForEach(Array(state.item.plan.enumerated()), id: \.offset) { offset, p in
                            HStack {
                                Text("Set \(offset + 1)")
                                Spacer()
                                Text("\(p.reps) reps • \(formattedWeight(p.weight)) kg")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        HStack {
                            Image(systemName: "timer")
                                .foregroundStyle(.secondary)
                            Text("Rest timer: \(state.item.restSeconds) s")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    } else {
                        // TRYB TRENINGU
                        if state.isCompleted {
                            HStack {
                                Spacer()
                                Label("Completed", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                            }
                        }
                        
                        ForEach($state.setsProgress) { $set in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Set \(set.index + 1)")
                                        .font(.headline)
                                    Spacer()
                                    Toggle("Done", isOn: $set.done)
                                        .labelsHidden()
                                        .onChange(of: set.done) { newValue in
                                            handleToggleDone(for: state.id, setIndex: set.index, newValue: newValue)
                                        }
                                }
                                
                                HStack {
                                    Stepper("Reps: \(set.repsDone)",
                                            value: $set.repsDone,
                                            in: 0...max(100, state.item.plan[set.index].reps))
                                }
                                
                                HStack {
                                    Stepper("Weight: \(formattedWeight(set.weight)) kg",
                                            value: $set.weight,
                                            in: 0...500,
                                            step: 2.5)
                                    .disabled(state.isResting)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if state.isResting {
                            HStack {
                                ProgressView(value: Double(state.restRemaining), total: Double(state.item.restSeconds))
                                    .progressViewStyle(.linear)
                                Text("\(state.restRemaining)s")
                                    .monospacedDigit()
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .animation(.default, value: state.restRemaining)
                            
                            Button { stopRest(for: state.id) } label: {
                                Text("Skip rest")
                            }
                        }
                        
                        HStack {
                            Button {
                                markNextSetDone(for: state.id)
                            } label: {
                                Text(state.nextSetIndexToComplete != nil ? "Next set completed" : "All sets completed")
                            }
                            .disabled(state.nextSetIndexToComplete == nil || state.isResting)
                            
                            Spacer()
                            
                            if !state.isCompleted {
                                Button("Exercise completed") {
                                    finishExercise(for: state.id)
                                }
                                .disabled(!state.allSetsDone)
                            }
                        }
                    }
                }
            }
            
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .id(isRunning)
        .navigationTitle(currentRoutine.name)
        .onAppear {
            if states.isEmpty {
                states = currentRoutine.items.map { RuntimeExerciseState(item: $0) }
            }
            // sprawdź, czy jest trening w toku dla tej rutyny
            if let _ = WorkoutInProgressStore.shared.load(routineName: currentRoutine.name) {
                // podpowiedz wznowienie
                askResume = true
            }
        }
        .onDisappear {
            stopWorkoutTimer()
        }
        // Reaguj na zmiany w RoutineStore i aktualizuj currentRoutine + states (jeśli nie trwa trening)
        .onReceive(routineStore.$routines) { _ in
            syncWithStoreIfUpdated()
        }
        .alert("Resume unfinished routine?", isPresented: $askResume) {
            Button("Nie", role: .cancel) {
                // nic – zostaw podgląd
            }
            Button("Resume") {
                resumeIfAvailable()
            }
        } message: {
            Text("Routine in progress.")
        }
        .sheet(isPresented: $showSummary) {
            if let summary {
                WorkoutSummaryView(summary: summary) {
                    // zamknij sheet i wróć do listy
                    showSummary = false
                    dismiss()
                }
            }
        }
        .toolbar {
            if !isRunning {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditRoutineView(routine: currentRoutine) { updated in
                routineStore.update(updated)
                // Po zapisie zaktualizuj lokalny stan natychmiast
                syncAfterEdit(updated: updated)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        Section(header: Text("Routine")) {
            let tint = iconTint(for: currentRoutine.iconName)
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.12))
                    Image(systemName: currentRoutine.iconName)
                        .foregroundStyle(tint)
                }
                .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentRoutine.name)
                        .font(.headline)
                    Text("Exercises: \(currentRoutine.items.count)")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                Spacer()
            }
            
            if isRunning {
                HStack {
                    Label(workoutTimeString, systemImage: "clock")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(role: .destructive) {
                        Task { await endAndSaveWorkout() }
                    } label: {
                        Text("End training")
                            .foregroundStyle(.red)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    Button {
                        startWorkout()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(.headline)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var workoutTimeString: String {
        let m = workoutElapsedSeconds / 60
        let s = workoutElapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // MARK: - Sync helpers
    
    private func syncWithStoreIfUpdated() {
        // Znajdź odpowiadającą rutynę w store po dbId (lub po nazwie fallback)
        let updated: Routine? = {
            if let dbId = routine.dbId {
                return routineStore.routines.first(where: { $0.dbId == dbId })
            } else {
                return routineStore.routines.first(where: { $0.name == routine.name })
            }
        }()
        guard let updated else { return }
        // Jeśli coś się zmieniło – podmień currentRoutine i ewentualnie odśwież states (tylko gdy nie trwa trening)
        if updated != currentRoutine {
            currentRoutine = updated
            if !isRunning {
                states = currentRoutine.items.map { RuntimeExerciseState(item: $0) }
            }
        }
    }
    
    private func syncAfterEdit(updated: Routine) {
        currentRoutine = updated
        if !isRunning {
            states = updated.items.map { RuntimeExerciseState(item: $0) }
        }
    }
    
    // MARK: - Workout timer control
    
    private func startWorkout() {
        isRunning = true
        workoutElapsedSeconds = 0
        stopWorkoutTimer()
        workoutTimerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                workoutElapsedSeconds += 1
                saveInProgressSnapshot()
            }
        }
        // pierwszy snapshot od razu
        saveInProgressSnapshot()
    }
    
    private func stopWorkoutTimer() {
        workoutTimerTask?.cancel()
        workoutTimerTask = nil
    }
    
    // MARK: - Save completed workout and show summary
    
    private func endAndSaveWorkout() async {
        stopWorkoutTimer()
        defer { isRunning = false }
        errorMessage = nil
        saveSuccess = false
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "User no logged in."
            return
        }
        
        let completedExercises: [DBCompletedExercise] = states.map { st in
            let sets: [DBCompletedSet] = st.setsProgress.map { sp in
                DBCompletedSet(index: sp.index, reps: sp.repsDone, weight: sp.weight, done: sp.done)
            }
            return DBCompletedExercise(
                exerciseId: st.item.exercise.id,
                exerciseName: st.item.exercise.name,
                restSeconds: st.item.restSeconds,
                sets: sets
            )
        }
        
        let completed = DBCompletedWorkout(
            routineId: nil,
            routineName: currentRoutine.name,
            routineIconName: currentRoutine.iconName, // ZAPISZ IKONĘ RUTYNY
            dateCompleted: Date(),
            durationSeconds: workoutElapsedSeconds,
            exercises: completedExercises
        )
        
        do {
            try await CompletedWorkoutsManager.shared.addCompletedWorkout(userId: auth.uid, workout: completed)
            saveSuccess = true
            // usuń stan in-progress
            WorkoutInProgressStore.shared.clear(routineName: currentRoutine.name)
            // policz podsumowanie i pokaż sheet
            let runtimeSnapshots = states.map { st in
                RuntimeExerciseSnapshot(
                    exerciseId: st.item.exercise.id,
                    exerciseName: st.item.exercise.name,
                    restSeconds: st.item.restSeconds,
                    sets: st.setsProgress.map {
                        RuntimeSetSnapshot(index: $0.index, repsDone: $0.repsDone, weight: $0.weight, done: $0.done)
                    }
                )
            }
            summary = WorkoutSummary.from(
                routineName: currentRoutine.name,
                durationSeconds: workoutElapsedSeconds,
                states: runtimeSnapshots
            )
            showSummary = true
        } catch {
            errorMessage = "Failed to save completed training: \(error.localizedDescription)"
        }
    }
    
    // MARK: - In-progress snapshot
    
    private func saveInProgressSnapshot() {
        guard isRunning else { return }
        let snapshots: [RuntimeExerciseSnapshot] = states.map { st in
            RuntimeExerciseSnapshot(
                exerciseId: st.item.exercise.id,
                exerciseName: st.item.exercise.name,
                restSeconds: st.item.restSeconds,
                sets: st.setsProgress.map {
                    RuntimeSetSnapshot(index: $0.index, repsDone: $0.repsDone, weight: $0.weight, done: $0.done)
                }
            )
        }
        let data = WorkoutInProgress(
            routineName: currentRoutine.name,
            startedAt: Date(),
            elapsedSeconds: workoutElapsedSeconds,
            exercises: snapshots
        )
        WorkoutInProgressStore.shared.save(routineName: currentRoutine.name, data: data)
    }
    
    private func resumeIfAvailable() {
        guard let saved = WorkoutInProgressStore.shared.load(routineName: currentRoutine.name) else { return }
        // odtwórz stany
        if states.isEmpty {
            states = currentRoutine.items.map { RuntimeExerciseState(item: $0) }
        }
        // mapuj z saved.exercises do states
        for i in states.indices {
            let exId = states[i].item.exercise.id
            if let snap = saved.exercises.first(where: { $0.exerciseId == exId }) {
                // zaktualizuj sety
                for j in states[i].setsProgress.indices {
                    let idx = states[i].setsProgress[j].index
                    if let s = snap.sets.first(where: { $0.index == idx }) {
                        states[i].setsProgress[j].repsDone = s.repsDone
                        states[i].setsProgress[j].weight = s.weight
                        states[i].setsProgress[j].done = s.done
                    }
                }
            }
        }
        workoutElapsedSeconds = saved.elapsedSeconds
        isRunning = true
        // uruchom timer
        stopWorkoutTimer()
        workoutTimerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                workoutElapsedSeconds += 1
                saveInProgressSnapshot()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formattedWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    // MARK: - Actions (only active in running mode)
    
    private func handleToggleDone(for stateId: UUID, setIndex: Int, newValue: Bool) {
        guard isRunning else { return }
        guard let idx = states.firstIndex(where: { $0.id == stateId }) else { return }
        states[idx].setsProgress[setIndex].done = newValue
        if newValue {
            startRest(for: stateId)
        }
        states[idx].recalculateCompletion()
        saveInProgressSnapshot()
    }
    
    private func markNextSetDone(for stateId: UUID) {
        guard isRunning else { return }
        guard let idx = states.firstIndex(where: { $0.id == stateId }) else { return }
        guard let next = states[idx].nextSetIndexToComplete else { return }
        states[idx].setsProgress[next].done = true
        startRest(for: stateId)
        states[idx].recalculateCompletion()
        saveInProgressSnapshot()
    }
    
    private func finishExercise(for stateId: UUID) {
        guard isRunning else { return }
        guard let idx = states.firstIndex(where: { $0.id == stateId }) else { return }
        for i in states[idx].setsProgress.indices {
            states[idx].setsProgress[i].done = true
        }
        stopRest(for: stateId)
        states[idx].recalculateCompletion()
        saveInProgressSnapshot()
    }
}

// MARK: - Runtime Models

private struct RuntimeExerciseState: Identifiable, Hashable {
    let id = UUID()
    var item: ExerciseInRoutine
    
    var setsProgress: [SetProgress]
    
    var isResting: Bool = false
    var restRemaining: Int = 0
    
    var allSetsDone: Bool {
        setsProgress.allSatisfy { $0.done }
    }
    var isCompleted: Bool { allSetsDone }
    var nextSetIndexToComplete: Int? {
        setsProgress.firstIndex(where: { !$0.done })
    }
    
    init(item: ExerciseInRoutine) {
        self.item = item
        self.setsProgress = item.plan.enumerated().map { offset, p in
            SetProgress(index: offset, repsDone: p.reps, weight: p.weight, done: false)
        }
        self.restRemaining = item.restSeconds
    }
    
    mutating func recalculateCompletion() {
        // ewentualna dodatkowa logika
    }
}

private struct SetProgress: Identifiable, Hashable {
    let id = UUID()
    let index: Int
    var repsDone: Int
    var weight: Double
    var done: Bool
}

// MARK: - Binding helpers

private extension RoutineDetailView {
    func startRestBinding(for index: Int) {
        states[index].isResting = true
        states[index].restRemaining = states[index].item.restSeconds
        
        Task { @MainActor in
            while states[index].isResting && states[index].restRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if index < states.count {
                    states[index].restRemaining -= 1
                }
            }
            if index < states.count {
                states[index].isResting = false
            }
        }
    }
    
    func startRest(for stateId: UUID) {
        guard let idx = states.firstIndex(where: { $0.id == stateId }) else { return }
        guard !states[idx].isResting else { return }
        startRestBinding(for: idx)
    }
    
    func stopRest(for stateId: UUID) {
        guard let idx = states.firstIndex(where: { $0.id == stateId }) else { return }
        states[idx].isResting = false
        states[idx].restRemaining = 0
    }
}
