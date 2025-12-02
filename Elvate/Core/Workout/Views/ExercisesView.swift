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
    // NOWE: zapamiętujemy kolejność kliknięć
    @State private var selectionOrder: [String] = []
    
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
                            // odznaczenie: usuń z Set i z kolejności
                            selectedIds.remove(exercise.id)
                            if let idx = selectionOrder.firstIndex(of: exercise.id) {
                                selectionOrder.remove(at: idx)
                            }
                        } else {
                            // zaznaczenie: dodaj do Set i na koniec kolejności
                            selectedIds.insert(exercise.id)
                            selectionOrder.append(exercise.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .environment(\.editMode, .constant(selectionMode ? .active : .inactive))
                .toolbar {
                    if selectionMode {
                        ToolbarItem(placement: .bottomBar) {
                            Button {
                                // Zbuduj wynik w kolejności kliknięć
                                let selectedByTapOrder: [Exercise] = selectionOrder.compactMap { id in
                                    viewModel.exercises.first(where: { $0.id == id })
                                }
                                onContinue?(selectedByTapOrder)
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
        .onChange(of: selectedIds) { _, _ in
            // Synchronizacja selectionOrder, gdyby zaznaczenie zmieniło się przez systemowy multi-select
            selectionOrder = selectionOrder.filter { selectedIds.contains($0) }
            // Dodaj ewentualnie nowe zaznaczenia, których jeszcze nie ma w kolejności
            for id in selectedIds where !selectionOrder.contains(id) {
                selectionOrder.append(id)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExercisesView(selectionMode: true) { _ in }
    }
}
