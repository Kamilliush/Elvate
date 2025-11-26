//
//  ExerciseViewModel.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import Foundation
import Combine

@MainActor
final class ExercisesViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadExercises() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try LocalExerciseService.shared.loadExercises()
            self.exercises = result
        } catch {
            self.errorMessage = "Nie udało się załadować ćwiczeń."
            print("Local JSON error:", error)
        }
        
        isLoading = false
    }
}
