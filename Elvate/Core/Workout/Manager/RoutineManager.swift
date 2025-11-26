import Foundation
import FirebaseFirestore
import FirebaseSharedSwift

struct DBSetPlan: Codable, Hashable {
    var reps: Int
    var weight: Double
}

struct DBRoutineExercise: Codable, Hashable {
    var exerciseId: String
    var exerciseName: String
    var restSeconds: Int
    var plan: [DBSetPlan]
}

struct DBRoutine: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var dateCreated: Date
    var items: [DBRoutineExercise]
}

final class RoutineManager {
    static let shared = RoutineManager()
    private init() {}
    
    private let users = Firestore.firestore().collection("users")
    
    private func routinesCollection(userId: String) -> CollectionReference {
        users.document(userId).collection("routines")
    }
    
    func addRoutine(userId: String, routine: DBRoutine) async throws {
        try routinesCollection(userId: userId).addDocument(from: routine)
    }
    
    func fetchRoutines(userId: String) async throws -> [DBRoutine] {
        let snap = try await routinesCollection(userId: userId)
            .order(by: "dateCreated", descending: false)
            .getDocuments()
        return try snap.documents.map { try $0.data(as: DBRoutine.self) }
    }
    
    func deleteRoutine(userId: String, routineId: String) async throws {
        try await routinesCollection(userId: userId).document(routineId).delete()
    }
}
