//
//  MeasurementEntryDetailView.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import SwiftUI

struct MeasurementEntryDetailView: View {
    let metric: MeasurementMetric
    let entry: DBMetricEntry
    
    var onChanged: (() -> Void)? = nil
    var onDeleted: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var valueText: String = ""
    @State private var isSaving: Bool = false
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showDeleteConfirm: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(metric.title)
                        .font(.largeTitle.bold())
                    Text(entry.dateCreated.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Details card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Entry details", systemImage: "info.circle")
                            .font(.headline)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Date")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.dateCreated.formatted(date: .abbreviated, time: .shortened))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    HStack {
                        Text("Current value")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f %@", entry.value, metric.unit))
                            .font(.headline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06))
                )
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                
                // Edit card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Edit value", systemImage: "square.and.pencil")
                            .font(.headline)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(metric.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 10) {
                                Image(systemName: "ruler")
                                    .foregroundStyle(.secondary)
                                TextField("Value", text: $valueText)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.primary)
                                Text(metric.unit)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.08))
                            )
                        }
                        
                        if let errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
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
                                Task { await save() }
                            } label: {
                                HStack {
                                    if isSaving { ProgressView().tint(.white) }
                                    Text(isSaving ? "Saving…" : "Save")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .disabled(isSaving || valueText.isEmpty)
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
            .padding(20)
        }
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            valueText = String(format: "%.1f", entry.value)
        }
        .alert("Delete entry?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await delete() }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Actions
    
    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "User not logged in."
            return
        }
        guard let id = entry.id else {
            errorMessage = "Missing entry id."
            return
        }
        let normalized = valueText.replacingOccurrences(of: ",", with: ".")
        guard let newValue = Double(normalized) else {
            errorMessage = "Type a correct numeric value."
            return
        }
        
        do {
            try await MeasurementsManager.shared.updateMetricEntry(
                userId: auth.uid,
                metricId: metric.metricId,
                documentId: id,
                newValue: newValue
            )
            onChanged?()
            await MainActor.run { dismiss() }
        } catch {
            errorMessage = "Cannot update: \(error.localizedDescription)"
        }
    }
    
    private func delete() async {
        errorMessage = nil
        isDeleting = true
        defer { isDeleting = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "User not logged in."
            return
        }
        guard let id = entry.id else {
            errorMessage = "Missing entry id."
            return
        }
        do {
            try await MeasurementsManager.shared.deleteMetricEntry(
                userId: auth.uid,
                metricId: metric.metricId,
                documentId: id
            )
            onDeleted?()
            await MainActor.run { dismiss() }
        } catch {
            errorMessage = "Cannot delete: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        MeasurementEntryDetailView(
            metric: .weight,
            entry: DBMetricEntry(id: "1", userId: "u", metricId: "weight", dateCreated: Date(), value: 75.3)
        )
    }
}

