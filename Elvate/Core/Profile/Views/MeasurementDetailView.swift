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
    
    // Edycja istniejącego wpisu
    @State private var editSheetPresented = false
    @State private var editValueText: String = ""
    @State private var editingEntryId: String? = nil
    
    init(metric: MeasurementMetric) {
        _viewModel = StateObject(wrappedValue: MeasurementDetailViewModel(metric: metric))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Form {
                // Zakres danych
                Section(header: Text("Range")) {
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
                        DatePicker("From", selection: $viewModel.customFrom, displayedComponents: .date)
                        DatePicker("To", selection: $viewModel.customTo, displayedComponents: .date)
                        Button("Apply") {
                            Task { await viewModel.loadWithCurrentRange() }
                        }
                    }
                }
                
                Section(header: Text("Edit")) {
                    HStack {
                        TextField("\(viewModel.metric.title)", text: $viewModel.inputText)
                            .keyboardType(.decimalPad)
                        Text(viewModel.metric.unit)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        Task { await viewModel.save() }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .font(.headline)
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("History")) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        let values = viewModel.history.map { $0.value }
                        let minVal = values.min() ?? 0
                        let maxVal = values.max() ?? 0
                        let span = max(maxVal - minVal, 0)
                        let baseMinPadding: Double = (viewModel.metric == .weight) ? 0.5 : 0.5
                        let padding = max(span * 0.1, baseMinPadding)
                        let lower = (span == 0) ? (minVal - baseMinPadding) : (minVal - padding)
                        let upper = (span == 0) ? (maxVal + baseMinPadding) : (maxVal + padding)
                        
                        Chart {
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
                        .chartYScale(domain: lower...upper)
                        .frame(height: 220)
                        
                        ForEach(Array(viewModel.history.enumerated()), id: \.element.id) { _, e in
                            HStack {
                                Text(e.dateCreated.formatted(date: .abbreviated, time: .shortened))
                                Spacer()
                                Text(String(format: "%.1f %@", e.value, viewModel.metric.unit))
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Edit") {
                                    editingEntryId = e.id
                                    editValueText = String(format: "%.1f", e.value)
                                    editSheetPresented = true
                                }
                                .tint(.blue)
                                
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(at: IndexSet(integer: index(of: e))) }
                                } label: {
                                    Text("Delete")
                                }
                            }
                        }
                        .onDelete { offsets in
                            Task { await viewModel.delete(at: offsets) }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.metric.title)
        .task {
            await viewModel.load()
        }
        // Lekki sheet do edycji wartości (zamiast alertu z TextField – brak natywnego)
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
    
    private func index(of entry: DBMetricEntry) -> Int {
        viewModel.history.firstIndex { $0.id == entry.id } ?? 0
    }
}

#Preview {
    NavigationStack {
        MeasurementDetailView(metric: .weight)
    }
}

