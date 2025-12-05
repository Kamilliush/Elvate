//
//  UserManagaer.swift
//  Elvate
//
//  Created by Kamil Jakut on 04/11/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseSharedSwift

struct DBUser: Codable {
    let userId: String
    let email: String?
    let photoUrl: String?
    let dateCreated: Date?
    let isPremium: Bool?
    let preferences: [String]?
    let displayName: String?   // NEW
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.email = auth.email
        self.photoUrl = auth.photoUrl
        self.dateCreated = Date()
        self.isPremium = false
        self.preferences = nil
        // Domyślna nazwa z prefiksu emaila lub "User"
        if let email = auth.email, let prefix = email.split(separator: "@").first, !prefix.isEmpty {
            self.displayName = String(prefix).capitalized
        } else {
            self.displayName = "User"
        }
    }
    
    init (
        userId: String,
        email: String? = nil,
        photoUrl: String? = nil,
        dateCreated: Date? = nil,
        isPremium: Bool? = nil,
        preferences: [String]? = nil,
        displayName: String? = nil    // NEW
    ) {
        self.userId = userId
        self.email = email
        self.photoUrl = photoUrl
        self.dateCreated = dateCreated
        self.isPremium = isPremium
        self.preferences = preferences
        self.displayName = displayName
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email = "email"
        case photoUrl = "photo_url"
        case dateCreated = "date_created"
        case isPremium = "user_isPremium"
        case preferences = "preferences"
        case displayName = "display_name"   // NEW
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium)
        self.preferences = try container.decodeIfPresent([String].self, forKey: .preferences)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) // NEW
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(self.isPremium, forKey: .isPremium)
        try container.encodeIfPresent(self.preferences, forKey: .preferences)
        try container.encodeIfPresent(self.displayName, forKey: .displayName) // NEW
    }
    
}

final class UserManager {
    
    static let shared = UserManager()
    private init() { }
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func createNewUser(user: DBUser) async throws {
        try userDocument(userId: user.userId).setData(from: user, merge: false)
    }
    
    func getUser(userId: String) async throws -> DBUser {
        try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
    func updateUserPremiumStatus(userId: String, isPremium: Bool) async throws {
        let data: [String:Any] = [
            DBUser.CodingKeys.isPremium.rawValue : isPremium
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func addUserPreference(userId: String, preference: String) async throws{
        let data: [String:Any] = [
            DBUser.CodingKeys.preferences.rawValue : FieldValue.arrayUnion([preference])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func removeUserPreference(userId: String, preference: String) async throws{
        let data: [String:Any] = [
            DBUser.CodingKeys.preferences.rawValue : FieldValue.arrayRemove([preference])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    // NEW: update display name
    func updateUserDisplayName(userId: String, displayName: String) async throws {
        let data: [String: Any] = [
            DBUser.CodingKeys.displayName.rawValue: displayName
        ]
        try await userDocument(userId: userId).updateData(data)
    }
}

