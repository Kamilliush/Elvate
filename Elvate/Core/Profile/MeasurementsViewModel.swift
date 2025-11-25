//
//  MeasurementsViewModel.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import Foundation
import Combine

@MainActor
final class MeasurementsViewModel: ObservableObject {
    // Pola formularza jako tekst (dla TextField)
    @Published var heightText: String = ""
    @Published var weightText: String = ""
    @Published var waistText: String = ""
    @Published var bicepsText: String = ""
    @Published var legText: String = ""
    @Published var chestText: String = ""
    
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var saveSuccess: Bool = false
    
    private func parseDouble(_ text: String) -> Double? {
        // Umożliwiamy kropkę i przecinek
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
    
    func save() async {
        errorMessage = nil
        saveSuccess = false
        
        guard let auth = try? AuthenticationManager.shared.getAuthenticatedUser() else {
            errorMessage = "Brak zalogowanego użytkownika."
            return
        }
        
        guard
            let height = parseDouble(heightText),
            let weight = parseDouble(weightText),
            let waist = parseDouble(waistText),
            let biceps = parseDouble(bicepsText),
            let leg = parseDouble(legText),
            let chest = parseDouble(chestText)
        else {
            errorMessage = "Uzupełnij poprawnie wszystkie pola liczbami (użyj . lub ,)."
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        let now = Date()
        
        do {
            // Zapisujemy każdy pomiar jako osobny wpis w odpowiedniej metryce,
            // używając tego samego znacznika czasu, aby tworzyły spójny zestaw.
            try await MeasurementsManager.shared.addMetricEntry(
                userId: auth.uid, metricId: MeasurementMetric.height.metricId, value: height, date: now
            )
            try await MeasurementsManager.shared.addMetricEntry(
                userId: auth.uid, metricId: MeasurementMetric.weight.metricId, value: weight, date: now
            )
            try await MeasurementsManager.shared.addMetricEntry(
                userId: auth.uid, metricId: MeasurementMetric.waist.metricId, value: waist, date: now
            )
            try await MeasurementsManager.shared.addMetricEntry(
                userId: auth.uid, metricId: MeasurementMetric.biceps.metricId, value: biceps, date: now
            )
            try await MeasurementsManager.shared.addMetricEntry(
                userId: auth.uid, metricId: MeasurementMetric.leg.metricId, value: leg, date: now
            )
            try await MeasurementsManager.shared.addMetricEntry(
                userId: auth.uid, metricId: MeasurementMetric.chest.metricId, value: chest, date: now
            )
            
            saveSuccess = true
            // Opcjonalnie czyścimy formularz:
            // clearForm()
        } catch {
            errorMessage = "Nie udało się zapisać: \(error.localizedDescription)"
        }
    }
    
    func clearForm() {
        heightText = ""
        weightText = ""
        waistText = ""
        bicepsText = ""
        legText = ""
        chestText = ""
    }
}

