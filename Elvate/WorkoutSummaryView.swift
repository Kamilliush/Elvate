import SwiftUI

struct WorkoutSummaryView: View {
    let summary: WorkoutSummary
    let onClose: () -> Void
    
    private var timeString: String {
        let m = summary.durationSeconds / 60
        let s = summary.durationSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func formattedWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Podsumowanie")) {
                    HStack {
                        Text("Trening")
                        Spacer()
                        Text(summary.routineName)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Czas")
                        Spacer()
                        Text(timeString)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Serie")
                        Spacer()
                        Text("\(summary.totalSets)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Powtórzenia")
                        Spacer()
                        Text("\(summary.totalReps)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Objętość")
                        Spacer()
                        Text("\(formattedWeight(summary.totalVolumeKg)) kg")
                            .foregroundStyle(.secondary)
                    }
                    if let ex = summary.heaviestExerciseName, let w = summary.heaviestWeight {
                        HStack {
                            Text("Najcięższe ćwiczenie")
                            Spacer()
                            Text("\(ex) • \(formattedWeight(w)) kg")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Podsumowanie")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Zamknij") { onClose() }
                }
            }
        }
    }
}
