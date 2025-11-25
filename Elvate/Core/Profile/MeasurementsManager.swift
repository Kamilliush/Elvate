//
//  MeasurementsManager.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseSharedSwift

struct DBMetricEntry: Codable, Identifiable {
    var id: String? = nil
    let userId: String
    let metricId: String   // np. "weight", "height" itd.
    let dateCreated: Date
    let value: Double
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case metricId = "metric_id"
        case dateCreated = "date_created"
        case value = "value"
    }
}

final class MeasurementsManager {
    static let shared = MeasurementsManager()
    private init() {}
    
    private let users = Firestore.firestore().collection("users")
    
    // users/{userId}/measurements/{metricId}/entries
    private func entriesCollection(userId: String, metricId: String) -> CollectionReference {
        users.document(userId)
            .collection("measurements")
            .document(metricId)
            .collection("entries")
    }
    
    func addMetricEntry(userId: String, metricId: String, value: Double, date: Date = Date()) async throws {
        let entry = DBMetricEntry(userId: userId, metricId: metricId, dateCreated: date, value: value)
        try entriesCollection(userId: userId, metricId: metricId).addDocument(from: entry)
    }
    
    func fetchMetricEntries(userId: String, metricId: String, limit: Int? = nil) async throws -> [DBMetricEntry] {
        var query: Query = entriesCollection(userId: userId, metricId: metricId)
            .order(by: DBMetricEntry.CodingKeys.dateCreated.rawValue, descending: false)
        if let limit { query = query.limit(to: limit) }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.map { doc in
            var e = try doc.data(as: DBMetricEntry.self)
            e.id = doc.documentID
            return e
        }
    }
    
    func deleteMetricEntry(userId: String, metricId: String, documentId: String) async throws {
        try await entriesCollection(userId: userId, metricId: metricId).document(documentId).delete()
    }
}
