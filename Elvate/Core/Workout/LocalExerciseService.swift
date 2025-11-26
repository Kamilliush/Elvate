//
//  LocalExerciseService.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import Foundation

final class LocalExerciseService {
    static let shared = LocalExerciseService()
    private init() {}
    
    func loadExercises() throws -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            throw NSError(domain: "LocalExerciseService", code: 1, userInfo: [NSLocalizedDescriptionKey : "Nie znaleziono pliku exercises.json"])
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Exercise].self, from: data)
    }
}
