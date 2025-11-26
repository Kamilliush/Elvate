import SwiftUI

struct CompletedWorkoutDetailView: View {
    let workout: DBCompletedWorkout
    
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert: Bool = false
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        List {
            Section(header: Text("Trening")) {
                Text(workout.routineName)
                    .font(.headline)
                HStack {
                    Text(workout.dateCompleted.formatted(date: .abbreviated, time: .shortened))
                    Spacer()
                    Text(timeString(workout.durationSeconds))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            
            ForEach(workout.exercises, id: \.exerciseId) { ex in
                Section(header: Text(ex.exerciseName)) {
                    ForEach(ex.sets.sorted(by: { $0.index < $1.index }), id: \.index) { s in
                        HStack {
                            Text("Seria \(s.index + 1)")
                            
                            Spacer()
                            
                            // opis serii
                            Text("\(s.reps) powt. • \(formattedWeight(s.weight)) kg")
                                .foregroundStyle(.secondary)
                            
                            // status: wykonano / nie wykonano
                            Image(systemName: s.done ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(s.done ? .green : .red)
                        }
                    }
                }
            }
        }
        .navigationTitle(workout.routineName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Usuń", systemImage: "trash")
                }
                .disabled(isDeleting || workout.id == nil)
            }
        }
        .alert("Usunąć ten zakończony trening?", isPresented: $showDeleteAlert) {
            Button("Anuluj", role: .cancel) {}
            Button("Usuń", role: .destructive) {
                Task { await deleteWorkout() }
            }
        } message: {
            Text("Tej operacji nie można cofnąć.")
        }
    }
    
    private func deleteWorkout() async {
        errorMessage = nil
        guard let docId = workout.id else {
            errorMessage = "Brak identyfikatora dokumentu."
            return
        }
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "Brak zalogowanego użytkownika."
            return
        }
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            try await CompletedWorkoutsManager.shared.deleteCompletedWorkout(userId: auth.uid, documentId: docId)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Nie udało się usunąć: \(error.localizedDescription)"
            }
        }
    }
    
    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func formattedWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
}
