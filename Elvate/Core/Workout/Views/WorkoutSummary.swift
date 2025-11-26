import Foundation

struct WorkoutSummary {
    let routineName: String
    let durationSeconds: Int
    let totalSets: Int
    let totalReps: Int
    let totalVolumeKg: Double
    let heaviestExerciseName: String?
    let heaviestWeight: Double?
    
    static func from(routineName: String, durationSeconds: Int, states: [RuntimeExerciseSnapshot]) -> WorkoutSummary {
        var sets = 0
        var reps = 0
        var volume: Double = 0
        var maxWeight: Double = 0
        var maxWeightExercise: String? = nil
        
        for s in states {
            for set in s.sets {
                sets += 1
                reps += set.repsDone
                volume += Double(set.repsDone) * set.weight
                if set.weight > maxWeight {
                    maxWeight = set.weight
                    maxWeightExercise = s.exerciseName
                }
            }
        }
        
        return WorkoutSummary(
            routineName: routineName,
            durationSeconds: durationSeconds,
            totalSets: sets,
            totalReps: reps,
            totalVolumeKg: volume,
            heaviestExerciseName: maxWeightExercise,
            heaviestWeight: maxWeight > 0 ? maxWeight : nil
        )
    }
}

// Prosty snapshot runtime do wyliczeń i zapisu w UserDefaults
struct RuntimeExerciseSnapshot: Codable {
    let exerciseId: String
    let exerciseName: String
    let restSeconds: Int
    let sets: [RuntimeSetSnapshot]
}

struct RuntimeSetSnapshot: Codable {
    let index: Int
    let repsDone: Int
    let weight: Double
    let done: Bool
}
