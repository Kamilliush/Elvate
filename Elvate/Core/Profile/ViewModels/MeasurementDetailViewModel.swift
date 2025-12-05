//
//  MeasurementDetailViewModel.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import Foundation
import Combine

enum MeasurementMetric: CaseIterable, Identifiable {
    case height, weight, waist, biceps, leg, chest
    
    var id: String { metricId }
    var title: String {
        switch self {
        case .height: return "Height"
        case .weight: return "Weight"
        case .waist:  return "Wais"
        case .biceps: return "Biceps"
        case .leg:    return "Thigh"
        case .chest:  return "Chest"
        }
    }
    var unit: String {
        switch self {
        case .weight: return "kg"
        default: return "cm"
        }
    }
    var metricId: String {
        switch self {
        case .height: return "height"
        case .weight: return "weight"
        case .waist:  return "waist"
        case .biceps: return "biceps"
        case .leg:    return "thigh"
        case .chest:  return "chest"
        }
    }
}

enum MeasurementsRange: String, CaseIterable, Identifiable {
    case all = "All"
    case year = "Year"
    case month = "Month"
    case week = "Week"
    case custom = "Custom"
    
    var id: String { rawValue }
}

@MainActor
final class MeasurementDetailViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var history: [DBMetricEntry] = []
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    
    // Zakres danych
    @Published var selectedRange: MeasurementsRange = .all
    @Published var customFrom: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var customTo: Date = Date()
    
    let metric: MeasurementMetric
    
    init(metric: MeasurementMetric) {
        self.metric = metric
    }
    
    func load() async {
        await loadWithCurrentRange()
    }
    
    func loadWithCurrentRange() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "User no logged in."
            return
        }
        
        do {
            let (from, to) = dateBounds(for: selectedRange)
            let items: [DBMetricEntry]
            if selectedRange == .all {
                items = try await MeasurementsManager.shared.fetchMetricEntries(
                    userId: auth.uid,
                    metricId: metric.metricId
                )
            } else {
                items = try await MeasurementsManager.shared.fetchMetricEntries(
                    userId: auth.uid,
                    metricId: metric.metricId,
                    from: from,
                    to: to
                )
            }
            history = items
            if let last = history.last {
                inputText = String(format: "%.1f", last.value)
            }
        } catch {
            errorMessage = "Cannot load history: \(error.localizedDescription)"
        }
    }
    
    private func parseDouble(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }
    
    func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "User no logged in."
            return
        }
        guard let newValue = parseDouble(inputText) else {
            errorMessage = "Type correct number value."
            return
        }
        
        do {
            try await MeasurementsManager.shared.addMetricEntry(
                userId: auth.uid,
                metricId: metric.metricId,
                value: newValue
            )
            await loadWithCurrentRange()
        } catch {
            errorMessage = "Cannot save \(error.localizedDescription)"
        }
    }
    
    func delete(at offsets: IndexSet) async {
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else { return }
        let idsToDelete: [String] = offsets.compactMap { idx in history[idx].id }
        for id in idsToDelete {
            do {
                try await MeasurementsManager.shared.deleteMetricEntry(
                    userId: auth.uid,
                    metricId: metric.metricId,
                    documentId: id
                )
            } catch {
                errorMessage = "Cannot delete: \(error.localizedDescription)"
            }
        }
        await loadWithCurrentRange()
    }
    
    // Edycja istniejącego wpisu (wartość, data bez zmian)
    func updateEntry(id: String, newValueText: String) async {
        errorMessage = nil
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "User no logged in."
            return
        }
        guard let newValue = parseDouble(newValueText) else {
            errorMessage = "Type correct number value."
            return
        }
        do {
            try await MeasurementsManager.shared.updateMetricEntry(
                userId: auth.uid,
                metricId: metric.metricId,
                documentId: id,
                newValue: newValue
            )
            await loadWithCurrentRange()
        } catch {
            errorMessage = "Cannot update: \(error.localizedDescription)"
        }
    }
    
    // Wylicz granice dat dla zakresu
    private func dateBounds(for range: MeasurementsRange) -> (Date?, Date?) {
        let now = Date()
        let cal = Calendar.current
        switch range {
        case .all:
            return (nil, nil)
        case .year:
            let from = cal.date(byAdding: .day, value: -365, to: now)
            return (from, now)
        case .month:
            let from = cal.date(byAdding: .day, value: -30, to: now)
            return (from, now)
        case .week:
            let from = cal.date(byAdding: .day, value: -7, to: now)
            return (from, now)
        case .custom:
            // Normalizujemy do początku/końca dnia aby inclusive działało intuicyjnie
            let start = cal.startOfDay(for: customFrom)
            let end = cal.date(bySettingHour: 23, minute: 59, second: 59, of: customTo) ?? customTo
            return (start, end)
        }
    }
}

