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
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    
                    statCardsRow
                    
                    detailsCard
                }
                .padding(20)
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") { onClose() }
                }
            }
        }
    }
    
    // MARK: - Cards
    
    private var heroCard: some View {
        let icon = "figure.strengthtraining.traditional"
        let tint = iconTint(for: icon)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.14))
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                }
                .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.routineName)
                        .font(.title3.weight(.semibold))
                    Text("Workout finished")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 10) {
                Label(timeString, systemImage: "clock")
                    .monospacedDigit()
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                
                Spacer()
                
                Button {
                    onClose()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
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
    
    private var statCardsRow: some View {
        HStack(spacing: 12) {
            statMiniCard(title: "Sets", value: "\(summary.totalSets)", icon: "square.stack.3d.up", tint: .blue)
            statMiniCard(title: "Reps", value: "\(summary.totalReps)", icon: "repeat", tint: .teal)
            statMiniCard(title: "Volume", value: "\(formattedWeight(summary.totalVolumeKg)) kg", icon: "scalemass", tint: .purple)
        }
    }
    
    private func statMiniCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.15))
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                }
                .frame(width: 28, height: 28)
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Details", systemImage: "info.circle")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 10) {
                row(label: "Training", value: summary.routineName)
                row(label: "Time", value: timeString, monospaced: true)
                row(label: "Sets", value: "\(summary.totalSets)")
                row(label: "Reps", value: "\(summary.totalReps)")
                row(label: "Volume", value: "\(formattedWeight(summary.totalVolumeKg)) kg")
                if let ex = summary.heaviestExerciseName, let w = summary.heaviestWeight {
                    row(label: "Most heavy exercise", value: "\(ex) • \(formattedWeight(w)) kg")
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
    
    private func row(label: String, value: String, monospaced: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(monospaced ? .body.monospacedDigit() : .body)
                .foregroundStyle(.primary.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

