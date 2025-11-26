import Foundation

struct WorkoutInProgress: Codable {
    let routineName: String
    let startedAt: Date
    let elapsedSeconds: Int
    let exercises: [RuntimeExerciseSnapshot]
}

final class WorkoutInProgressStore {
    static let shared = WorkoutInProgressStore()
    private init() {}
    
    private let keyPrefix = "workout_in_progress_"
    
    private func key(for routineName: String) -> String {
        keyPrefix + routineName
    }
    
    func save(routineName: String, data: WorkoutInProgress) {
        let key = key(for: routineName)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func load(routineName: String) -> WorkoutInProgress? {
        let key = key(for: routineName)
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WorkoutInProgress.self, from: data)
    }
    
    func clear(routineName: String) {
        let key = key(for: routineName)
        UserDefaults.standard.removeObject(forKey: key)
    }
}
