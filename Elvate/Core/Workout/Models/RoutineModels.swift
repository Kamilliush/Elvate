import Foundation
import Combine

struct SetPlan: Identifiable, Hashable {
    let id: UUID = UUID()
    var reps: Int
    var weight: Double
}

struct ExerciseInRoutine: Identifiable, Hashable {
    let id: UUID = UUID()
    let exercise: Exercise
    var plan: [SetPlan]           // per-seria: powtórzenia i ciężar
    var restSeconds: Int
}

struct Routine: Identifiable, Hashable {
    let id: UUID = UUID()
    var dbId: String?                 // Firestore document id
    var name: String
    var items: [ExerciseInRoutine]
    var dateCreated: Date = Date()
    var iconName: String = "figure.strengthtraining.traditional"
}

