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
    
    // Ikony do wyboru
    private let availableIcons: [String] = [
        "figure.strengthtraining.traditional",
        "dumbbell",
        "figure.run",
        "figure.walk",
        "bicycle",
        "heart.fill",
        "flame.fill",
        "bolt.fill",
        "star.fill",
        "leaf.fill"
    ]
    @State private var selectedIconName: String = "figure.strengthtraining.traditional"
    
    init(exercises: [Exercise]) {
        self.exercises = exercises
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Nazwa rutyny
                VStack(alignment: .leading, spacing: 8) {
                    Text("Routine name")
                        .font(.headline)
                    TextField("Push day", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // Wybór ikony
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose icon")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    IconGrid(icons: availableIcons, selected: $selectedIconName)
                }
                
                // Ćwiczenia i parametry
                VStack(alignment: .leading, spacing: 12) {
                    Text("Personalize exercises")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    ForEach($items) { $item in
                        ExerciseCard(item: $item)
                    }
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                if saveSuccess {
                    Label("Routine saved", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                
                // Zapisz
                Button {
                    Task { await saveRoutine() }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "Saving…" : "Save routine")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(items.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                }
                .disabled(items.isEmpty || isSaving)
            }
            .padding(20)
        }
        .navigationTitle("Personlalize")
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
            errorMessage = "User no logged in."
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
            items: dbItems,
            iconName: selectedIconName
        )
        
        do {
            try await RoutineManager.shared.addRoutine(userId: auth.uid, routine: dbRoutine)
            // Aktualizuj lokalny store, aby UI od razu widziało
            var uiRoutine = Routine(name: routineName, items: items)
            uiRoutine.iconName = selectedIconName
            routineStore.add(uiRoutine)
            saveSuccess = true
            dismiss()
            dismiss()
        } catch {
            errorMessage = "Cannot save routine: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helpers
    
    private func defaultPlan(sets: Int, reps: Int, weight: Double) -> [SetPlan] {
        (0..<sets).map { _ in SetPlan(reps: reps, weight: weight) }
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

private struct IconGrid: View {
    let icons: [String]
    @Binding var selected: String
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(icons, id: \.self) { icon in
                let tint = iconTint(for: icon)
                Button {
                    selected = icon
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selected == icon ? tint.opacity(0.18) : Color.gray.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selected == icon ? tint : Color.clear, lineWidth: 2)
                            )
                        Image(systemName: icon)
                            .foregroundStyle(selected == icon ? tint : Color.primary)
                    }
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ExerciseCard: View {
    @Binding var item: ExerciseInRoutine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Nagłówek ćwiczenia
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(.blue)
                }
                .frame(width: 36, height: 36)
                
                Text(item.exercise.name)
                    .font(.headline)
                Spacer()
            }
            
            // Liczba serii
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up")
                    .foregroundStyle(.secondary)
                Stepper("Number of sets: \(item.plan.count)", value: Binding(
                    get: { item.plan.count },
                    set: { newCount in
                        adjustPlanCount(for: &item.plan, to: newCount)
                    }
                ), in: 1...10)
            }
            
            // Seria x: reps + ciężar
            VStack(spacing: 10) {
                ForEach($item.plan) { $setPlan in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set \(seriesIndex(in: item.plan, id: setPlan.id) + 1)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "repeat")
                                .foregroundStyle(.secondary)
                            Stepper("Reps: \(setPlan.reps)", value: $setPlan.reps, in: 1...50)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "scalemass")
                                .foregroundStyle(.secondary)
                            Stepper("Weight: \(formattedWeight(setPlan.weight)) kg",
                                    value: $setPlan.weight,
                                    in: 0...500,
                                    step: 2.5)
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            
            // Przerwa
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .foregroundStyle(.secondary)
                Stepper("Rest timer: \(item.restSeconds) s", value: $item.restSeconds, in: 15...600, step: 15)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
    
    // Helpers (lokalnie, by nie mieszać w logice widoku głównego)
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
}
