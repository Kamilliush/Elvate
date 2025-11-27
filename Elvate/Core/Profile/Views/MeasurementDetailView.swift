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
    
    init(metric: MeasurementMetric) {
        _viewModel = StateObject(wrappedValue: MeasurementDetailViewModel(metric: metric))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Form {
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
                        .frame(height: 220)
                        
                        ForEach(Array(viewModel.history.enumerated()), id: \.element.id) { _, e in
                            HStack {
                                Text(e.dateCreated.formatted(date: .abbreviated, time: .shortened))
                                Spacer()
                                Text(String(format: "%.1f %@", e.value, viewModel.metric.unit))
                                    .foregroundStyle(.secondary)
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
    }
}

#Preview {
    NavigationStack {
        MeasurementDetailView(metric: .weight)
    }
}
