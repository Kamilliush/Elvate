//
//  MeasurementDetailView.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import SwiftUI
import Charts

struct MeasurementDetailView: View {
    @StateObject private var viewModel: MeasurementDetailViewModel
    
    // Kept for backward compatibility (not used for navigation now)
    @State private var editSheetPresented = false
    @State private var editValueText: String = ""
    @State private var editingEntryId: String? = nil
    
    init(metric: MeasurementMetric) {
        _viewModel = StateObject(wrappedValue: MeasurementDetailViewModel(metric: metric))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.metric.title)
                        .font(.largeTitle.bold())
                    Text("Track and edit your \(viewModel.metric.title.lowercased()) measurements.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Range card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Range", systemImage: "calendar")
                            .font(.headline)
                        Spacer()
                    }
                    
                    VStack(spacing: 10) {
                        Picker("Range", selection: $viewModel.selectedRange) {
                            ForEach(MeasurementsRange.allCases) { r in
                                Text(r.rawValue).tag(r)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.selectedRange) { _, _ in
                            Task { await viewModel.loadWithCurrentRange() }
                        }
                        
                        if viewModel.selectedRange == .custom {
                            VStack(spacing: 10) {
                                dateField(title: "From", date: $viewModel.customFrom)
                                dateField(title: "To", date: $viewModel.customTo)
                                Button {
                                    Task { await viewModel.loadWithCurrentRange() }
                                } label: {
                                    Text("Apply")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
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
                
                // Edit card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Add / Edit", systemImage: "square.and.pencil")
                            .font(.headline)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Input field
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.metric.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 10) {
                                Image(systemName: "ruler")
                                    .foregroundStyle(.secondary)
                                TextField("\(viewModel.metric.title)", text: $viewModel.inputText)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.primary)
                                Text(viewModel.metric.unit)
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
                        
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button {
                            Task { await viewModel.save() }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isSaving { ProgressView().tint(.white) }
                                Text(viewModel.isSaving ? "Saving…" : "Save")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        }
                        .disabled(viewModel.isSaving || viewModel.inputText.isEmpty)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06))
                )
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                
                // History card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("History", systemImage: "clock")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Group {
                        if viewModel.isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Loading history…")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        } else if viewModel.history.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.secondary)
                                Text("No data yet")
                                    .font(.headline)
                                Text("Add your first measurement to see trends.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        } else {
                            chartView
                            
                            VStack(spacing: 10) {
                                ForEach(Array(viewModel.history.enumerated()), id: \.element.id) { _, e in
                                    NavigationLink {
                                        MeasurementEntryDetailView(
                                            metric: viewModel.metric,
                                            entry: e,
                                            onChanged: { Task { await viewModel.loadWithCurrentRange() } },
                                            onDeleted: { Task { await viewModel.loadWithCurrentRange() } }
                                        )
                                    } label: {
                                        historyRow(e)
                                    }
                                }
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
            }
            .padding(20)
        }
        .navigationTitle(viewModel.metric.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $editSheetPresented) {
            NavigationStack {
                Form {
                    Section(header: Text("Edit value")) {
                        HStack {
                            TextField("Value", text: $editValueText)
                                .keyboardType(.decimalPad)
                            Text(viewModel.metric.unit)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Edit")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editSheetPresented = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard let id = editingEntryId else { return }
                            Task {
                                await viewModel.updateEntry(id: id, newValueText: editValueText)
                                editSheetPresented = false
                            }
                        }
                    }
                }
            }
            .presentationDetents([.height(220), .medium])
        }
    }
    
    // MARK: - Components
    
    private var chartView: some View {
        let values = viewModel.history.map { $0.value }
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0
        let span = max(maxVal - minVal, 0)
        let baseMinPadding: Double = 0.5
        let padding = max(span * 0.1, baseMinPadding)
        let lower = (span == 0) ? (minVal - baseMinPadding) : (minVal - padding)
        let upper = (span == 0) ? (maxVal + baseMinPadding) : (maxVal + padding)
        
        return Chart {
            ForEach(viewModel.history, id: \.id) { e in
                LineMark(
                    x: .value("Date", e.dateCreated),
                    y: .value(viewModel.metric.title, e.value)
                )
                PointMark(
                    x: .value("Date", e.dateCreated),
                    y: .value(viewModel.metric.title, e.value)
                )
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
        .chartYScale(domain: lower...upper)
        .frame(height: 220)
    }
    
    private func historyRow(_ e: DBMetricEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(e.dateCreated.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
            Text(String(format: "%.1f %@", e.value, viewModel.metric.unit))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func dateField(title: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                DatePicker("", selection: date, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08))
            )
        }
    }
    
    private func index(of entry: DBMetricEntry) -> Int {
        viewModel.history.firstIndex { $0.id == entry.id } ?? 0
    }
}

#Preview {
    NavigationStack {
        MeasurementDetailView(metric: .weight)
    }
}

