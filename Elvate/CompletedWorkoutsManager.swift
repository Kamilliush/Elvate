import Foundation
import FirebaseFirestore
import FirebaseSharedSwift

struct DBCompletedSet: Codable, Hashable {
    var index: Int
    var reps: Int
    var weight: Double
    var done: Bool
}

struct DBCompletedExercise: Codable, Hashable {
    var exerciseId: String
    var exerciseName: String
    var restSeconds: Int
    var sets: [DBCompletedSet]
}

struct DBCompletedWorkout: Codable, Identifiable {
    @DocumentID var id: String?
    var routineId: String?          // opcjonalnie
    var routineName: String
    var dateCompleted: Date
    var durationSeconds: Int
    var exercises: [DBCompletedExercise]
}

final class CompletedWorkoutsManager {
    static let shared = CompletedWorkoutsManager()
    private init() {}
    
    private let users = Firestore.firestore().collection("users")
    
    private func completedCollection(userId: String) -> CollectionReference {
        users.document(userId).collection("completedWorkouts")
    }
    
    func addCompletedWorkout(userId: String, workout: DBCompletedWorkout) async throws {
        try completedCollection(userId: userId).addDocument(from: workout)
    }
    
    func fetchCompleted(userId: String, limit: Int? = nil) async throws -> [DBCompletedWorkout] {
        var query: Query = completedCollection(userId: userId)
            .order(by: "dateCompleted", descending: true)
        if let limit { query = query.limit(to: limit) }
        let snap = try await query.getDocuments()
        return try snap.documents.map { try $0.data(as: DBCompletedWorkout.self) }
    }
}
