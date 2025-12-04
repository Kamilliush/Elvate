//
//  MeasurementsView.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import SwiftUI

struct MeasurementsView: View {
    private let metrics: [MeasurementMetric] = MeasurementMetric.allCases
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // HEADER
                VStack(alignment: .leading, spacing: 6) {
                    Text("Measurements")
                        .font(.largeTitle.bold())
                    Text("Track your body metrics over time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // CARD
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Your metrics", systemImage: "ruler")
                            .font(.headline)
                        Spacer()
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(metrics) { metric in
                            NavigationLink {
                                MeasurementDetailView(metric: metric)
                            } label: {
                                metricRow(metric)
                            }
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
                
                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .navigationTitle("Measurements")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Row
    
    private func metricRow(_ metric: MeasurementMetric) -> some View {
        let (icon, tint) = iconForMetric(metric)
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.15))
                Image(systemName: icon)
                    .foregroundStyle(tint)
            }
            .frame(width: 34, height: 34)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(metric.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Icons
    
    private func iconForMetric(_ metric: MeasurementMetric) -> (String, Color) {
        switch metric {
        case .weight: return ("scalemass", .purple)
        case .height: return ("arrow.up.and.down", .blue)
        case .waist:  return ("ruler", .teal)
        case .biceps: return ("ruler", .teal)
        case .leg:    return ("ruler", .teal)
        case .chest:  return ("ruler", .teal)
        }
    }
}

#Preview {
    NavigationStack {
        MeasurementsView()
    }
}
