import SwiftUI

struct CompletedWorkoutDetailView: View {
    let workout: DBCompletedWorkout
    
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
