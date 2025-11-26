//
//  Exercises.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import SwiftUI
import Combine

struct ExercisesView: View {
    @StateObject private var viewModel = ExercisesViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Ładowanie…")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text(error)
                    Button("Spróbuj ponownie") {
                        Task { await viewModel.loadExercises() }
                    }
                }
            } else {
                List(viewModel.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                        
                        Text("Category: \(exercise.category)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Primary muscles: \(exercise.primaryMuscles.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Ćwiczenia")
        .task {
            await viewModel.loadExercises()
        }
    }
}

#Preview {
    NavigationStack {
        ExercisesView()
    }
}
