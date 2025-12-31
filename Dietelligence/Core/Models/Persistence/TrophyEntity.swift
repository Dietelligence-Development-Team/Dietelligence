//
//  TrophyEntity.swift
//  Dietelligence
//
//  SwiftData persistence model for trophies
//

import Foundation
import SwiftData

@Model
final class TrophyEntity {
    @Attribute(.unique) var id: UUID
    var type: String  // TrophyType.rawValue
    var earnedDate: Date
    var streakDays: Int

    // Nutrition stats snapshot
    var calories: Double
    var protein: Double
    var fat: Double
    var carbohydrate: Double

    /// Convert type string to enum
    var typeEnum: TrophyType {
        TrophyType(rawValue: type) ?? .singleDay
    }

    init(trophy: Trophy) {
        self.id = trophy.id
        self.type = trophy.type.rawValue
        self.earnedDate = trophy.earnedDate
        self.streakDays = trophy.streakDays
        self.calories = trophy.calories
        self.protein = trophy.protein
        self.fat = trophy.fat
        self.carbohydrate = trophy.carbohydrate
    }

    /// Convert entity back to domain model
    func toTrophy() -> Trophy {
        Trophy(
            id: id,
            type: typeEnum,
            earnedDate: earnedDate,
            streakDays: streakDays,
            calories: calories,
            protein: protein,
            fat: fat,
            carbohydrate: carbohydrate
        )
    }
}
