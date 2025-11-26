//
//  Exercise.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import Foundation

struct Exercise: Identifiable, Decodable {
    let id: String
    let name: String
    let force: String?
    let level: String?
    let mechanic: String?
    let equipment: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
    let category: String
    let images: [String]
}
