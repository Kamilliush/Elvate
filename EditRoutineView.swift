import SwiftUI

struct EditRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var routineStore: RoutineStore
    
    let routine: Routine
    var onSaved: (Routine) -> Void
    
    @State private var name: String
    @State private var items: [ExerciseInRoutine]
    @State private var iconName: String
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    
    // Delete state
    @State private var showDeleteConfirm: Bool = false
    @State private var isDeleting: Bool = false
    @State private var deleteErrorMessage: String? = nil
    
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
    
    init(routine: Routine, onSaved: @escaping (Routine) -> Void) {
        self.routine = routine
        self.onSaved = onSaved
        _name = State(initialValue: routine.name)
        _items = State(initialValue: routine.items)
        _iconName = State(initialValue: routine.iconName)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    nameCard
                    iconCard
                    parametersCard
                    
                    if let errorMessage {
                        errorCard(errorMessage)
                    }
                    if let deleteErrorMessage {
                        errorCard(deleteErrorMessage)
                    }
                    
                    actionButtons
                }
                .padding(20)
            }
            .navigationTitle("Edit routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(isDeleting || routine.dbId == nil)
                }
            }
            .alert("Delete routine “\(routine.name)”?",
                   isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await deleteRoutine() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Cards
    
    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Routine name", systemImage: "text.cursor")
                    .font(.headline)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("e.g. Push Day", text: $name)
                    .textFieldStyle(.roundedBorder)
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
    
    private var iconCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Routine icon", systemImage: "app.dashed")
                    .font(.headline)
                Spacer()
            }
            IconGridInline(icons: availableIcons, selected: $iconName)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Exercise parameters", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Spacer()
            }
            VStack(spacing: 12) {
                ForEach($items) { $item in
                    exerciseParametersCard(item: $item)
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
    
    private func exerciseParametersCard(item: Binding<ExerciseInRoutine>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Text(item.wrappedValue.exercise.name)
                    .font(.headline)
                Spacer()
            }
            
            // Sets count
            HStack(spacing: 12) {
                Image(systemName: "square.stack.3d.up")
                    .foregroundStyle(.secondary)
                Stepper("Number of sets: \(item.wrappedValue.plan.count)", value: Binding(
                    get: { item.wrappedValue.plan.count },
                    set: { newCount in
                        adjustPlanCount(for: &item.wrappedValue.plan, to: newCount)
                    }
                ), in: 1...10)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Per-set parameters
            VStack(spacing: 10) {
                ForEach(item.plan) { $setPlan in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set \(seriesIndex(in: item.wrappedValue.plan, id: setPlan.id) + 1)")
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
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.06))
                    )
                }
            }
            
            // Rest timer
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .foregroundStyle(.secondary)
                Stepper("Rest: \(item.wrappedValue.restSeconds) s", value: item.restSeconds, in: 15...600, step: 15)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
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
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack {
                    if isDeleting { ProgressView().tint(.white) }
                    Text(isDeleting ? "Deleting…" : "Delete")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isDeleting)
            
            Button {
                Task { await saveChanges() }
            } label: {
                HStack {
                    if isSaving { ProgressView().tint(.white) }
                    Text(isSaving ? "Saving…" : "Save")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(items.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            }
            .disabled(isSaving || items.isEmpty)
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "User not logged in."
            return
        }
        guard let docId = routine.dbId else {
            errorMessage = "Missing routine id."
            return
        }
        
        let dbItems: [DBRoutineExercise] = items.map { it in
            DBRoutineExercise(
                exerciseId: it.exercise.id,
                exerciseName: it.exercise.name,
                restSeconds: it.restSeconds,
                plan: it.plan.map { DBSetPlan(reps: $0.reps, weight: $0.weight) }
            )
        }
        let dbRoutine = DBRoutine(
            id: docId,
            name: name.isEmpty ? routine.name : name,
            dateCreated: routine.dateCreated,
            items: dbItems,
            iconName: iconName
        )
        
        do {
            try await RoutineManager.shared.updateRoutine(userId: auth.uid, routineId: docId, routine: dbRoutine)
            var updated = Routine(dbId: docId, name: dbRoutine.name, items: items, dateCreated: dbRoutine.dateCreated)
            updated.iconName = iconName
            onSaved(updated)
            dismiss()
        } catch {
            errorMessage = "Failed to update routine: \(error.localizedDescription)"
        }
    }
    
    private func deleteRoutine() async {
        deleteErrorMessage = nil
        isDeleting = true
        defer { isDeleting = false }
        
        guard let dbId = routine.dbId else {
            await MainActor.run {
                routineStore.routines.removeAll { $0.id == routine.id }
                dismiss()
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
                dismiss()
            }
        } catch {
            await MainActor.run {
                deleteErrorMessage = "Failed to delete routine: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helpers
    
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

private struct IconGridInline: View {
    let icons: [String]
    @Binding var selected: String
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(icons, id: \.self) { icon in
                let tint = iconTint(for: icon)
                Button {
                    selected = icon
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selected == icon ? tint.opacity(0.18) : Color.gray.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(selected == icon ? tint : Color.clear, lineWidth: 2)
                            )
                        Image(systemName: icon)
                            .foregroundStyle(selected == icon ? tint : Color.primary)
                    }
                    .frame(height: 36)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}
