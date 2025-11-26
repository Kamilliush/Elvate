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
    
    // Tryb wyboru dla tworzenia rutyny
    let selectionMode: Bool
    let onContinue: (([Exercise]) -> Void)?
    
    init(selectionMode: Bool = false, onContinue: (([Exercise]) -> Void)? = nil) {
        self.selectionMode = selectionMode
        self.onContinue = onContinue
    }
    
    @State private var selectedIds: Set<String> = []
    
    // Wyszukiwanie i filtrowanie
    @State private var searchText: String = ""
    @State private var selectedPrimaryMuscles: Set<String> = []
    @State private var showFilters: Bool = false
    
    private var allPrimaryMuscles: [String] {
        // Unikalne mięśnie z załadowanych ćwiczeń (posortowane alfabetycznie)
        let muscles = viewModel.exercises.flatMap { $0.primaryMuscles }
        return Array(Set(muscles)).sorted()
    }
    
    private var filteredExercises: [Exercise] {
        viewModel.exercises.filter { ex in
            // filtr po nazwie
            let matchesName: Bool
            if searchText.isEmpty {
                matchesName = true
            } else {
                matchesName = ex.name.localizedCaseInsensitiveContains(searchText)
            }
            // filtr po primary muscles (jeśli nie wybrano żadnego – przepuść wszystkie)
            let matchesMuscles: Bool
            if selectedPrimaryMuscles.isEmpty {
                matchesMuscles = true
            } else {
                // ćwiczenie musi zawierać przynajmniej jeden z wybranych mięśni
                matchesMuscles = !Set(ex.primaryMuscles).intersection(selectedPrimaryMuscles).isEmpty
            }
            return matchesName && matchesMuscles
        }
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading…")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text(error)
                    Button("Try again") {
                        Task { await viewModel.loadExercises() }
                    }
                }
            } else {
                List(filteredExercises, selection: selectionMode ? $selectedIds : .constant([])) { exercise in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)
                            
                            Text("Category: \(exercise.category)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // pokaż primary muscles skrótowo
                            if !exercise.primaryMuscles.isEmpty {
                                Text("Primary muscle: \(exercise.primaryMuscles.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                       
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard selectionMode else { return }
                        if selectedIds.contains(exercise.id) {
                            selectedIds.remove(exercise.id)
                        } else {
                            selectedIds.insert(exercise.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .environment(\.editMode, .constant(selectionMode ? .active : .inactive))
                .toolbar {
                    if selectionMode {
                        ToolbarItem(placement: .bottomBar) {
                            Button {
                                let selected = viewModel.exercises.filter { selectedIds.contains($0.id) }
                                onContinue?(selected)
                            } label: {
                                Text("Next (\(selectedIds.count))")
                                    .font(.headline)
                            }
                            .disabled(selectedIds.isEmpty)
                        }
                    }
                    // Filtry po primary muscles
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            // Szybkie akcje
                            if !selectedPrimaryMuscles.isEmpty {
                                Button("Clear filters") {
                                    selectedPrimaryMuscles.removeAll()
                                }
                            }
                            // Lista mięśni do wyboru
                            Section(header: Text("Primary muscles")) {
                                if allPrimaryMuscles.isEmpty {
                                    Text("No muscle data available")
                                } else {
                                    ForEach(allPrimaryMuscles, id: \.self) { muscle in
                                        let isOn = selectedPrimaryMuscles.contains(muscle)
                                        Button {
                                            if isOn { selectedPrimaryMuscles.remove(muscle) }
                                            else { selectedPrimaryMuscles.insert(muscle) }
                                        } label: {
                                            HStack {
                                                Text(muscle.capitalized)
                                                Spacer()
                                                if isOn {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } label: {
                            if selectedPrimaryMuscles.isEmpty {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            } else {
                                Label("\(selectedPrimaryMuscles.count)", systemImage: "line.3.horizontal.decrease.circle.fill")
                            }
                        }
                    }
                }
                // Pasek wyszukiwania po nazwie
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search exercise")
            }
        }
        .navigationTitle("Exercises")
        .task {
            await viewModel.loadExercises()
        }
    }
}

#Preview {
    NavigationStack {
        ExercisesView(selectionMode: true) { _ in }
    }
}
