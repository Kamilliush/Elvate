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
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                
                if let errorMessage {
                    errorCard(errorMessage)
                }
                
                // Ćwiczenia
                VStack(alignment: .leading, spacing: 12) {
                    Text(isRunning ? "Training" : "Preview")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    ForEach($states) { $state in
                        exerciseCard($state)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(currentRoutine.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if states.isEmpty {
                states = currentRoutine.items.map { RuntimeExerciseState(item: $0) }
            }
            if let _ = WorkoutInProgressStore.shared.load(routineName: currentRoutine.name) {
                askResume = true
            }
        }
        .onDisappear {
            stopWorkoutTimer()
        }
        .onReceive(routineStore.$routines) { _ in
            syncWithStoreIfUpdated()
        }
        .alert("Resume unfinished routine?", isPresented: $askResume) {
            Button("Nie", role: .cancel) {}
            Button("Resume") {
                resumeIfAvailable()
            }
        } message: {
            Text("Routine in progress.")
        }
        .sheet(isPresented: $showSummary) {
            if let summary {
                WorkoutSummaryView(summary: summary) {
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
                syncAfterEdit(updated: updated)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerCard: some View {
        let tint = iconTint(for: currentRoutine.iconName)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.14))
                    Image(systemName: currentRoutine.iconName)
                        .foregroundStyle(tint)
                }
                .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentRoutine.name)
                        .font(.title3.weight(.semibold))
                    HStack(spacing: 8) {
                        Text("\(currentRoutine.items.count) exercises")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if isRunning {
                            Text("In progress")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
            }
            
            if isRunning {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text(workoutTimeString)
                            .monospacedDigit()
                            .font(.headline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    Button {
                        Task { await endAndSaveWorkout() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                            Text("End training")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack {
                    Spacer()
                    Button {
                        startWorkout()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Start")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    Spacer()
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
    
    private func exerciseCard(_ state: Binding<RuntimeExerciseState>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(state.wrappedValue.item.exercise.name)
                    .font(.headline)
                Spacer()
                if isRunning, state.wrappedValue.isCompleted {
                    Text("Completed")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.18))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
            }
            
            if !isRunning {
                // PODGLĄD
                VStack(spacing: 8) {
                    ForEach(Array(state.wrappedValue.item.plan.enumerated()), id: \.offset) { offset, p in
                        HStack {
                            Text("Set \(offset + 1)")
                            Spacer()
                            Text("\(p.reps) reps • \(formattedWeight(p.weight)) kg")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .foregroundStyle(.secondary)
                        Text("Rest timer: \(state.wrappedValue.item.restSeconds) s")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .font(.footnote)
                    .padding(.horizontal, 4)
                }
            } else {
                
                VStack(spacing: 10) {
                    ForEach(state.setsProgress) { $set in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Set \(set.index + 1)")
                                    .font(.headline)
                                Spacer()
                                
                               
                                Button {
                                    let newValue = !set.done
                                    set.done = newValue
                                    handleToggleDone(for: state.wrappedValue.id, setIndex: set.index, newValue: newValue)
                                } label: {
                                    Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(set.done ? .green : .secondary)
                                        .font(.system(size: 22, weight: .semibold))
                                        .transaction { $0.animation = nil }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(set.done ? "Set done" : "Mark set done")
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "repeat")
                                    .foregroundStyle(.secondary)
                                Stepper("Reps: \(set.repsDone)",
                                        value: $set.repsDone,
                                        in: 0...max(100, state.wrappedValue.item.plan[set.index].reps))
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "scalemass")
                                    .foregroundStyle(.secondary)
                                Stepper("Weight: \(formattedWeight(set.weight)) kg",
                                        value: $set.weight,
                                        in: 0...500,
                                        step: 2.5)
                                .disabled(state.wrappedValue.isResting)
                            }
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    if state.wrappedValue.isResting {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                ProgressView(value: Double(state.wrappedValue.restRemaining), total: Double(state.wrappedValue.item.restSeconds))
                                    .progressViewStyle(.linear)
                                Text("\(state.wrappedValue.restRemaining)s")
                                    .monospacedDigit()
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .animation(.default, value: state.wrappedValue.restRemaining)
                            
                            Button { stopRest(for: state.wrappedValue.id) } label: {
                                Text("Skip rest")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    HStack {
                        Button {
                            markNextSetDone(for: state.wrappedValue.id)
                        } label: {
                            Text(state.wrappedValue.nextSetIndexToComplete != nil ? "Next set completed" : "All sets completed")
                                .font(.headline)
                        }
                        .disabled(state.wrappedValue.nextSetIndexToComplete == nil || state.wrappedValue.isResting)
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                        
                        if !state.wrappedValue.isCompleted {
                            Button("Exercise completed") {
                                finishExercise(for: state.wrappedValue.id)
                            }
                            .disabled(!state.wrappedValue.allSetsDone)
                            .buttonStyle(.bordered)
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
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
    
    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var workoutTimeString: String {
        let m = workoutElapsedSeconds / 60
        let s = workoutElapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // MARK: - Sync helpers
    
    private func syncWithStoreIfUpdated() {
        let updated: Routine? = {
            if let dbId = routine.dbId {
                return routineStore.routines.first(where: { $0.dbId == dbId })
            } else {
                return routineStore.routines.first(where: { $0.name == routine.name })
            }
        }()
        guard let updated else { return }
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
            routineId: currentRoutine.dbId,
            routineName: currentRoutine.name,
            routineIconName: currentRoutine.iconName,
            dateCompleted: Date(),
            durationSeconds: workoutElapsedSeconds,
            exercises: completedExercises
        )
        
        do {
            try await CompletedWorkoutsManager.shared.addCompletedWorkout(userId: auth.uid, workout: completed)
            saveSuccess = true
            WorkoutInProgressStore.shared.clear(routineName: currentRoutine.name)
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
        if states.isEmpty {
            states = currentRoutine.items.map { RuntimeExerciseState(item: $0) }
        }
        for i in states.indices {
            let exId = states[i].item.exercise.id
            if let snap = saved.exercises.first(where: { $0.exerciseId == exId }) {
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

