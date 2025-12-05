// IconTint.swift
import SwiftUI

func iconTint(for iconName: String) -> Color {
    switch iconName {
    case "figure.strengthtraining.traditional": return .green
    case "dumbbell", "dumbbell.fill": return .mint
    case "figure.run": return .orange
    case "figure.walk": return .brown
    case "bicycle": return .teal
    case "heart.fill": return .pink
    case "flame.fill": return .red
    case "bolt.fill": return .yellow
    case "star.fill": return .indigo
    case "leaf.fill": return .green
    case "figure.yoga": return .purple
    case "figure.core.training": return .indigo
    case "figure.rower": return .cyan
    case "figure.cooldown": return .gray
    default:
        return .accentColor
    }
}
