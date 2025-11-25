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
        case .height: return "Wzrost"
        case .weight: return "Waga"
        case .waist:  return "Talia"
        case .biceps: return "Biceps"
        case .leg:    return "Udo"
        case .chest:  return "Klatka"
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
        case .leg:    return "leg"
        case .chest:  return "chest"
        }
    }
}

@MainActor
final class MeasurementDetailViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var history: [DBMetricEntry] = []
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    
    let metric: MeasurementMetric
    
    init(metric: MeasurementMetric) {
        self.metric = metric
    }
    
    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "Brak zalogowanego użytkownika."
            return
        }
        
        do {
            let items = try await MeasurementsManager.shared.fetchMetricEntries(
                userId: auth.uid,
                metricId: metric.metricId
            )
            history = items
            if let last = history.last {
                inputText = String(format: "%.1f", last.value)
            }
        } catch {
            errorMessage = "Nie udało się pobrać historii: \(error.localizedDescription)"
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
            errorMessage = "Brak zalogowanego użytkownika."
            return
        }
        guard let newValue = parseDouble(inputText) else {
            errorMessage = "Podaj poprawną wartość liczbową."
            return
        }
        
        do {
            try await MeasurementsManager.shared.addMetricEntry(
                userId: auth.uid,
                metricId: metric.metricId,
                value: newValue
            )
            await load()
        } catch {
            errorMessage = "Nie udało się zapisać: \(error.localizedDescription)"
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
                errorMessage = "Nie udało się usunąć: \(error.localizedDescription)"
            }
        }
        await load()
    }
}
