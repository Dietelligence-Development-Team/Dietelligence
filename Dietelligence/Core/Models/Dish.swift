//
//  Dish.swift
//  Dietelligence
//
//  Created by Claude on 2025.
//

import SwiftUI

/// 菜品模型 - 包含多个食材成分
struct Dish: Identifiable, Equatable {
    let id = UUID()
    let name: String              // 菜品名称
    let icon: String              // Emoji 图标
    var ingredients: [FoodIngredient]  // 食材列表

    // MARK: - 计算总营养值

    /// 总重量（克）
    var totalWeight: Double {
        ingredients.reduce(0) { $0 + $1.weight }
    }

    /// 总卡路里
    var totalCalories: Double {
        ingredients.reduce(0) { $0 + $1.calories }
    }

    /// 总蛋白质重量（克）
    var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.proteinWeight }
    }

    /// 总脂肪重量（克）
    var totalFat: Double {
        ingredients.reduce(0) { $0 + $1.fatWeight }
    }

    /// 总碳水化合物重量（克）
    var totalCarbohydrate: Double {
        ingredients.reduce(0) { $0 + $1.carbohydrateWeight }
    }

    /// 总营养素重量（用于计算百分比）
    var totalNutrients: Double {
        totalProtein + totalFat + totalCarbohydrate
    }

    // MARK: - 营养素百分比（用于显示比例条）

    /// 蛋白质百分比 (0-100)
    var proteinPercent: Double {
        guard totalNutrients > 0 else { return 0 }
        return (totalProtein / totalNutrients) * 100
    }

    /// 脂肪百分比 (0-100)
    var fatPercent: Double {
        guard totalNutrients > 0 else { return 0 }
        return (totalFat / totalNutrients) * 100
    }

    /// 碳水化合物百分比 (0-100)
    var carbohydratePercent: Double {
        guard totalNutrients > 0 else { return 0 }
        return (totalCarbohydrate / totalNutrients) * 100
    }

    /// 可用百分比总和（用于比例条宽度计算）
    var available: Double {
        carbohydratePercent + proteinPercent + fatPercent
    }
}

extension Dish {
    static func == (lhs: Dish, rhs: Dish) -> Bool {
        lhs.name == rhs.name &&
        lhs.icon == rhs.icon &&
        lhs.ingredients == rhs.ingredients
    }
}

// MARK: - 示例数据
extension Dish {
    static let sampleData: [Dish] = [
        Dish(
            name: "Guizhou Sour Soup Fish",
            icon: "🐟",
            ingredients: FoodIngredient.sampleData
        ),
        Dish(
            name: "Steamed White Rice",
            icon: "🍚",
            ingredients: [
                FoodIngredient(
                    name: "Steamed White Rice",
                    icon: "🍚",
                    weight: 150,
                    proteinPercent: 2.6,
                    fatPercent: 0.3,
                    carbohydratePercent: 25.9
                )
            ]
        )
    ]
}
