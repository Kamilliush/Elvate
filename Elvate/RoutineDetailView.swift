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
    
    var body: some View {
        List {
            headerSection
            
            ForEach($states) { $state in
                Section(header: Text(state.item.exercise.name)) {
                    if !isRunning {
                        // PODGLĄD
                        ForEach(Array(state.item.plan.enumerated()), id: \.offset) { offset, p in
                            HStack {
                                Text("Seria \(offset + 1)")
                                Spacer()
                                Text("\(p.reps) powt. • \(formattedWeight(p.weight)) kg")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        HStack {
                            Image(systemName: "timer")
                                .foregroundStyle(.secondary)
                            Text("Przerwa: \(state.item.restSeconds) s")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    } else {
                        // TRYB TRENINGU
                        if state.isCompleted {
                            HStack {
                                Spacer()
                                Label("Zakończono", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                            }
                        }
                        
                        ForEach($state.setsProgress) { $set in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Seria \(set.index + 1)")
                                        .font(.headline)
                                    Spacer()
                                    Toggle("Wykonana", isOn: $set.done)
                                        .labelsHidden()
                                        .onChange(of: set.done) { newValue in
                                            handleToggleDone(for: state.id, setIndex: set.index, newValue: newValue)
                                        }
                                }
                                
                                HStack {
                                    Stepper("Powtórzenia: \(set.repsDone)",
                                            value: $set.repsDone,
                                            in: 0...max(100, state.item.plan[set.index].reps))
                                }
                                
                                HStack {
                                    Stepper("Ciężar: \(formattedWeight(set.weight)) kg",
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
                                Text("Pomiń przerwę")
                            }
                        }
                        
                        HStack {
                            Button {
                                markNextSetDone(for: state.id)
                            } label: {
                                Text(state.nextSetIndexToComplete != nil ? "Zakończ następną serię" : "Wszystkie serie zakończone")
                            }
                            .disabled(state.nextSetIndexToComplete == nil || state.isResting)
                            
                            Spacer()
                            
                            if !state.isCompleted {
                                Button("Zakończ ćwiczenie") {
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
            if saveSuccess {
                Section {
                    Label("Zapisano zakończony trening", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            }
        }
        .id(isRunning)
        .navigationTitle(routine.name)
        .onAppear {
            if states.isEmpty {
                states = routine.items.map { RuntimeExerciseState(item: $0) }
            }
        }
        .onDisappear {
            stopWorkoutTimer()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        Section(header: Text("Rutyna")) {
            Text(routine.name)
                .font(.headline)
            
            if isRunning {
                HStack {
                    Label(workoutTimeString, systemImage: "clock")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(role: .destructive) {
                        Task { await endAndSaveWorkout() }
                    } label: {
                        Text("Zakończ trening")
                            .foregroundStyle(.red)
                    }
                }
            } else {
                Text("Ćwiczeń: \(routine.items.count)")
                    .foregroundStyle(.secondary)
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
    
    // MARK: - Workout timer control
    
    private func startWorkout() {
        isRunning = true
        workoutElapsedSeconds = 0
        stopWorkoutTimer()
        workoutTimerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                workoutElapsedSeconds += 1
            }
        }
    }
    
    private func stopWorkoutTimer() {
        workoutTimerTask?.cancel()
        workoutTimerTask = nil
    }
    
    // MARK: - Save completed workout
    
    private func endAndSaveWorkout() async {
        stopWorkoutTimer()
        defer { isRunning = false }
        errorMessage = nil
        saveSuccess = false
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "Brak zalogowanego użytkownika."
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
            routineId: nil, // jeśli będziesz miał id z DBRoutine, możesz je tu podać
            routineName: routine.name,
            dateCompleted: Date(),
            durationSeconds: workoutElapsedSeconds,
            exercises: completedExercises
        )
        
        do {
            try await CompletedWorkoutsManager.shared.addCompletedWorkout(userId: auth.uid, workout: completed)
            saveSuccess = true
        } catch {
            errorMessage = "Nie udało się zapisać zakończonego treningu: \(error.localizedDescription)"
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
    }
    
    private func markNextSetDone(for stateId: UUID) {
        guard isRunning else { return }
        guard let idx = states.firstIndex(where: { $0.id == stateId }) else { return }
        guard let next = states[idx].nextSetIndexToComplete else { return }
        states[idx].setsProgress[next].done = true
        startRest(for: stateId)
        states[idx].recalculateCompletion()
    }
    
    private func finishExercise(for stateId: UUID) {
        guard isRunning else { return }
        guard let idx = states.firstIndex(where: { $0.id == stateId }) else { return }
        for i in states[idx].setsProgress.indices {
            states[idx].setsProgress[i].done = true
        }
        stopRest(for: stateId)
        states[idx].recalculateCompletion()
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
