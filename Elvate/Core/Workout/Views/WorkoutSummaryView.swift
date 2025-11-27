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
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Training")
                        Spacer()
                        Text(summary.routineName)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Time")
                        Spacer()
                        Text(timeString)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Sets")
                        Spacer()
                        Text("\(summary.totalSets)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Reps")
                        Spacer()
                        Text("\(summary.totalReps)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Volume")
                        Spacer()
                        Text("\(formattedWeight(summary.totalVolumeKg)) kg")
                            .foregroundStyle(.secondary)
                    }
                    if let ex = summary.heaviestExerciseName, let w = summary.heaviestWeight {
                        HStack {
                            Text("Most heavy exercise")
                            Spacer()
                            Text("\(ex) • \(formattedWeight(w)) kg")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") { onClose() }
                }
            }
        }
    }
}
