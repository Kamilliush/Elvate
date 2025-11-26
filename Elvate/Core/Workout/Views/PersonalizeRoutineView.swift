import SwiftUI

struct PersonalizeRoutineView: View {
    @EnvironmentObject private var routineStore: RoutineStore
    
    let exercises: [Exercise]
    
    @State private var name: String = ""
    @State private var items: [ExerciseInRoutine] = []
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var saveSuccess: Bool = false
    
    init(exercises: [Exercise]) {
        self.exercises = exercises
    }
    
    var body: some View {
        Form {
            Section(header: Text("Nazwa rutyny")) {
                TextField("Np. Push Day", text: $name)
            }
            
            Section(header: Text("Parametry ćwiczeń")) {
                ForEach($items) { $item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.exercise.name)
                            .font(.headline)
                        
                        Stepper("Liczba serii: \(item.plan.count)", value: Binding(
                            get: { item.plan.count },
                            set: { newCount in
                                adjustPlanCount(for: &item.plan, to: newCount)
                            }
                        ), in: 1...10)
                        
                        ForEach($item.plan) { $setPlan in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Seria \(seriesIndex(in: item.plan, id: setPlan.id) + 1)")
                                    .font(.subheadline.bold())
                                
                                HStack {
                                    Stepper("Powtórzenia: \(setPlan.reps)", value: $setPlan.reps, in: 1...50)
                                }
                                HStack {
                                    Stepper("Ciężar: \(formattedWeight(setPlan.weight)) kg",
                                            value: $setPlan.weight,
                                            in: 0...500,
                                            step: 2.5)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Stepper("Przerwa: \(item.restSeconds) s", value: $item.restSeconds, in: 15...600, step: 15)
                    }
                    .padding(.vertical, 6)
                }
            }
            
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
            if saveSuccess {
                Section { Label("Rutyna zapisana", systemImage: "checkmark.circle").foregroundStyle(.green) }
            }
            
            Section {
                Button {
                    Task { await saveRoutine() }
                } label: {
                    if isSaving { ProgressView() }
                    else { Text("Zapisz rutynę").font(.headline) }
                }
                .disabled(items.isEmpty || isSaving)
            }
        }
        .navigationTitle("Personalizacja")
        .onAppear {
            if items.isEmpty {
                items = exercises.map { ex in
                    ExerciseInRoutine(
                        exercise: ex,
                        plan: defaultPlan(sets: 3, reps: 10, weight: 0),
                        restSeconds: 90
                    )
                }
            }
        }
    }
    
    // MARK: - Save to Firestore
    
    private func saveRoutine() async {
        errorMessage = nil
        saveSuccess = false
        isSaving = true
        defer { isSaving = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "Brak zalogowanego użytkownika."
            return
        }
        let routineName = name.isEmpty ? defaultName() : name
        
        let dbItems: [DBRoutineExercise] = items.map { it in
            DBRoutineExercise(
                exerciseId: it.exercise.id,
                exerciseName: it.exercise.name,
                restSeconds: it.restSeconds,
                plan: it.plan.map { DBSetPlan(reps: $0.reps, weight: $0.weight) }
            )
        }
        let dbRoutine = DBRoutine(
            id: nil,
            name: routineName,
            dateCreated: Date(),
            items: dbItems
        )
        
        do {
            try await RoutineManager.shared.addRoutine(userId: auth.uid, routine: dbRoutine)
            // Opcjonalnie aktualizuj lokalny store, aby UI od razu widziało
            let uiRoutine = Routine(name: routineName, items: items)
            routineStore.add(uiRoutine)
            saveSuccess = true
            dismiss()
            dismiss()
        } catch {
            errorMessage = "Nie udało się zapisać rutyny: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helpers
    
    private func defaultPlan(sets: Int, reps: Int, weight: Double) -> [SetPlan] {
        (0..<sets).map { _ in SetPlan(reps: reps, weight: weight) }
    }
    
    private func adjustPlanCount(for plan: inout [SetPlan], to newCount: Int) {
        let current = plan.count
        if newCount > current {
            let template = plan.last ?? SetPlan(reps: 10, weight: 0)
            for _ in current..<newCount {
                plan.append(SetPlan(reps: template.reps, weight: template.weight))
            }
        } else if newCount < current {
            plan.removeLast(current - newCount)
        }
    }
    
    private func seriesIndex(in plan: [SetPlan], id: UUID) -> Int {
        plan.firstIndex { $0.id == id } ?? 0
    }
    
    private func formattedWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    private func defaultName() -> String {
        if let first = exercises.first?.category {
            return "\(first.capitalized) Routine"
        }
        return "New Routine"
    }
}
