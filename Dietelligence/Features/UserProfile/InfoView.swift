//
//  InfoView.swift
//  Dietelligence
//
//  Created by Cosmos on 14/10/2025.
//

import SwiftUI
import UIKit

// 纯输入页面（无 welcome、无后退）
struct InfoView: View {
    var initialName: String? = nil
    var onFinished: (() -> Void)? = nil
    var showResetButton: Bool = true

    var body: some View {
        ZStack{
            Color.backGround
            InfoInputList(
                initialName: initialName,
                onFinished: onFinished,
                showResetButton: showResetButton
            )
                .padding(20)
        }
        .ignoresSafeArea()
    }
}

struct InfoInputList: View {
    @Environment(\.dismiss) private var dismiss
    @State var name: String = ""
    let initialName: String?
    let onFinished: (() -> Void)?
    let showResetButton: Bool
    
    // --- 原有状态 ---
    @State private var selected: [String] = []
    @State private var BMI: Double = -1
    @State private var weightValue: Int = 70
    @State private var heightValue: Int = 170

    // --- 新增状态 (New State Variables) ---
    @State private var age: Int = 25
    // Gender 使用 CGFloat 以便制作滑块动画 (0.0 = Male, 1.0 = Female)
    @State private var genderValue: CGFloat = 0.0
    @State private var activityLevelIndex: Int = 0
    @State private var dietPreference: String = ""
    @State private var otherNotes: String = ""
    @State private var keyboardHeight: CGFloat = 0

    // 原始目标列表
    let selectList: [String] = [
        "Build Muscle",
        "Lose Fat",
        "Maintain Weight",
        "Gain Weight",
        "Improve Endurance",
        "Increase Strength",
        "Improve Flexibility",
        "General Fitness",
        "Body Recomposition"
    ]
    
    // 活动水平选项 (更专业易懂的描述 - 精简版)
    struct ActivityOption: Hashable {
        let id: Int
        let title: String
        let desc: String
    }
    
    let activityOptionsData: [ActivityOption] = [
        ActivityOption(id: 0, title: "Sedentary", desc: "No exercise"),
        ActivityOption(id: 1, title: "Lightly Active", desc: "1-3 days/wk"),
        ActivityOption(id: 2, title: "Moderately Active", desc: "4-5 days/wk"),
        ActivityOption(id: 3, title: "Active", desc: "Daily or 3-4 intense"),
        ActivityOption(id: 4, title: "Very Active", desc: "6-7 intense days"),
        ActivityOption(id: 5, title: "Extra Active", desc: "Physical job/training")
    ]

    init(initialName: String? = nil, onFinished: (() -> Void)? = nil, showResetButton: Bool = true) {
        self.initialName = initialName
        self.onFinished = onFinished
        self.showResetButton = showResetButton

        let profile = UserProfileManager.shared.getProfile()
        let resolvedName = (initialName?.isEmpty == false ? initialName! : (profile.name.isEmpty ? "" : profile.name))

        _name = State(initialValue: resolvedName)
        _selected = State(initialValue: profile.goals)
        _weightValue = State(initialValue: Int(profile.weight))
        _heightValue = State(initialValue: Int(profile.height))
        _age = State(initialValue: profile.age)
        _genderValue = State(initialValue: profile.gender.lowercased() == "female" ? 1.0 : 0.0)
        if let idx = activityOptionsData.firstIndex(where: { $0.title == profile.activityLevel }) {
            _activityLevelIndex = State(initialValue: idx)
        }
        _dietPreference = State(initialValue: profile.preference)
        _otherNotes = State(initialValue: profile.other)
        _BMI = State(initialValue: CalculateBMI(weight: Int(profile.weight), height: Int(profile.height)))
    }

    var body: some View {
        VStack{
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 120)

                    // --- Header ---
                    VStack(alignment: .leading){
                        HStack(alignment: .bottom){
                            Text("Hi")
                            TypewriterTextInput(
                                text: name.isEmpty ? "" : name,
                                font: .largeTitle,
                                fontWeight: .heavy,
                                alignment: .leading,
                                input: $name
                            )
                            .offset(y:1)
                        }
                        Text("welcome !")
                    }
                    .font(.largeTitle)
                    .fontDesign(.serif)
                    .fontWeight(.heavy)
                    .foregroundStyle(.mainText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    

                    Spacer().frame(height: 30)

                    Text("I need some \ninformation to work better for you.")
                        .font(.subheadline)
                        .fontDesign(.serif)
                        .fontWeight(.heavy)
                        .foregroundStyle(.mainText)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity,alignment: .leading)
                        .padding(.horizontal)

                    
                    // --- Section 2: Age & Gender (Compact Style) ---
                    // 整体作为一个Block，用粗横线分割
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 3)
                            .padding(.horizontal)
                        
                        // Age Row (Smaller Stepper)
                        HStack {
                            Text("Age")
                                .font(.headline) // Smaller font
                                .fontWeight(.bold)
                                .fontDesign(.serif)
                                .foregroundStyle(.mainText)
                            
                            Spacer()
                            
                            HStack(spacing: 15) {
                                Button(action: { if age > 10 { age -= 1 } }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .bold)) // Smaller icon
                                        .frame(width: 28, height: 28) // Smaller button size
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(style: .init(lineWidth: 2))
                                        )
                                }
                                .foregroundStyle(.userEnable)
                                
                                Text("\(age)")
                                    .font(.system(size: 20, weight: .heavy, design: .serif))
                                    .foregroundStyle(.mainText)
                                    .frame(width: 40)
                                
                                Button(action: { if age < 100 { age += 1 } }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold)) // Smaller icon
                                        .frame(width: 28, height: 28) // Smaller button size
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(style: .init(lineWidth: 2))
                                        )
                                }
                                .foregroundStyle(.userEnable)
                            }
                        }
                        .padding(.vertical, 10) // Reduced padding
                        .padding(.horizontal)
                        
                        // Divider inside the block
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 2)
                            .padding(.horizontal)
                        
                        // Gender Row (Smaller Slider)
                        HStack {
                            Text("Gender")
                                .font(.headline) // Smaller font
                                .fontWeight(.bold)
                                .fontDesign(.serif)
                                .foregroundStyle(.mainText)
                            
                            Spacer()
                            
                            // Custom Slider (Compact)
                            HStack {
                                ZStack(alignment: .leading) {
                                    // Track
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(style: .init(lineWidth: 2))
                                        .foregroundStyle(.mainText)
                                    
                                    // Thumb
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.userEnable)
                                        .frame(width: 78, height: 30 - 4)
                                        .padding(.leading,2)
                                        .offset(x: genderValue * 78, y: 0)
                                        .animation(.easeInOut(duration: 0.3), value: genderValue)
                                    
                                    HStack {
                                        Text("Male")
                                            .foregroundStyle(genderValue < 0.5 ? .backGround : .userEnable)
                                            .frame(maxWidth: .infinity)
                                        Text("Female")
                                            .foregroundStyle(genderValue > 0.5 ? .backGround : .userEnable)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .frame(width: 160)
                                    .font(.system(size: 14,weight: .bold ,design: .serif))
                                    .animation(.easeInOut(duration: 0.3), value: genderValue)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    genderValue = genderValue < 0.5 ? 1.0 : 0.0
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if value.location.x > 160 / 2 {
                                                genderValue = 1.0
                                            } else {
                                                genderValue = 0.0
                                            }
                                        }
                                )
                                .frame(width: 160,height: 30)
                            }
                        }
                        .padding(.top, 10) // Reduced padding
                        .padding(.horizontal)
                    }

                    // --- Section 3: BMI (Reordered: Now after Age/Gender) ---
                    // BMIInput has its own internal spacing/lines, fitting the style
                    BMIInput(weightValue: $weightValue, heightValue: $heightValue, BMI: $BMI)
                        .padding(.vertical, 10)

                    // --- Section 4: Activity Level (Reordered) ---
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 3)
                            .padding(.horizontal)
                        
                        Text("Daily Activity")
                            .font(.subheadline)
                            .fontDesign(.serif)
                            .fontWeight(.heavy)
                            .foregroundStyle(.mainText)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 2)
                            .padding(.horizontal)
                        
                        Picker("Activity Level", selection: $activityLevelIndex) {
                            ForEach(activityOptionsData, id: \.id) { option in
                                Text("\(option.title) (\(option.desc))")
                                    .font(.system(size: 16, design: .serif))
                                    .foregroundStyle(.userEnable)
                                    .tag(option.id)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100) // Slightly more compact
                        .clipped()
                        .padding(.horizontal)
                    }
                    
                    Rectangle()
                        .fill(.mainText)
                        .frame(height: 3)
                        .padding(.horizontal)

                    // --- Section 1: Goals (Existing) ---
                    sectionTitle("Which goals interest you?")

                    LazyVGrid(columns: Array(repeatElement(GridItem(.flexible()), count: 3)),spacing: 0) {
                        ForEach(selectList, id: \.self){ option in
                            Button{
                                if let ind = selected.firstIndex(of: option) {
                                    selected.remove(at: ind)
                                } else {
                                    selected.append(option)
                                }
                            } label: {
                                SelectableButtonContent(text: option, isSelected: selected.contains(option))
                            }
                        }
                        .padding(10)
                    }
                    .padding(.horizontal)
                    
                    Rectangle()
                        .fill(.mainText)
                        .frame(height: 3)
                        .padding(.horizontal)
                        .padding(.top,10)

                    // --- Section 5: Diet & Notes (Reordered & Underline Style) ---
                    VStack(alignment: .leading, spacing: 10) {
                        CustomTextField(title: "Dietary Preference", placeholder: "e.g. Vegetarian", text: $dietPreference)
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 2)
                        CustomTextField(title: "Other Notes", placeholder: "Allergies, injuries...", text: $otherNotes)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Rectangle()
                        .fill(.mainText)
                        .frame(height: 3)
                        .padding(.horizontal)
                        .padding(.top,10)
                    
                    Spacer().frame(height: 30)

                    Button{
                        saveProfile()
                    } label: {
                        Text("Done")
                            .fontDesign(.serif)
                            .fontWeight(.bold)
                            .foregroundStyle(.userEnable)
                            .padding(5)
                            .frame(width: 80)
                    }
                    .buttonStyle(.glass)
                    .disabled(BMI == -1 || name.isEmpty)

                    if showResetButton {
                        Button {
                            resetProfile()
                        } label: {
                            Text("Reset")
                                .fontDesign(.serif)
                                .fontWeight(.bold)
                                .foregroundStyle(.mainEnable)
                                .padding(5)
                                .frame(width: 80)
                        }
                        .buttonStyle(.glass)
                        .padding(.vertical, 5)

                        //Button {
                        //    generateTestData()
                        //} label: {
                        //    Text("Add Test Data")
                        //        .fontDesign(.serif)
                        //        .fontWeight(.bold)
                        //        .foregroundStyle(.userEnable)
                        //        .padding(5)
                        //        .frame(width: 140)
                        //}
                        //.buttonStyle(.glass)
                        //.padding(.vertical, 5)
                    }

                    Spacer().frame(height: 40)

                }
                .animation(.easeInOut(duration: 0.6), value: name.isEmpty)
            }
            .scrollIndicators(.never)
            .scrollDismissesKeyboard(.interactively)
            .padding(.bottom, keyboardHeight)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = frame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }

        }
    }
    
    // Helper view for consistent button style
    struct SelectableButtonContent: View {
        let text: String
        let isSelected: Bool
        
        var body: some View {
            if isSelected {
                Text(text)
                    .font(.system(size: 15, design: .serif))
                    .fontWeight(.heavy)
                    .padding(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(style: .init(lineWidth: 2.5))
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.backGround)
                                    .shadow(radius: 3)
                            )
                    )
                    .foregroundStyle(.userEnable)
            } else {
                Text(text)
                    .font(.system(size: 15, design: .serif))
                    .fontWeight(.semibold)
                    .padding(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(style: .init(lineWidth: 2.5))
                    )
                    .foregroundStyle(.mainText)
            }
        }
    }
    
    // Helper for Section Titles
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontDesign(.serif)
            .fontWeight(.heavy)
            .foregroundStyle(.mainText)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.horizontal, 10)
            .padding(.top, 5)
    }

    private func selectedGender() -> String {
        genderValue < 0.5 ? "Male" : "Female"
    }

    private func selectedActivityTitle() -> String {
        if activityLevelIndex < activityOptionsData.count {
            return activityOptionsData[activityLevelIndex].title
        }
        return "Moderately Active"
    }

    private func saveProfile() {
        let profile = UserNutritionProfile(
            name: name,
            weight: Double(weightValue),
            height: Double(heightValue),
            age: age,
            gender: selectedGender(),
            activityLevel: selectedActivityTitle(),
            goals: selected,
            preference: dietPreference,
            other: otherNotes
        )
        UserProfileManager.shared.saveProfile(profile)

        // Generate nutrition targets in background
        // Always regenerate when profile is saved to ensure targets match current profile
        Task {
            do {
                guard let apiKey = GeminiConfiguration.apiKey else {
                    print("⚠️ No API key, skipping nutrition targets generation")
                    return
                }

                print("🔄 Generating nutrition targets...")
                try await UserProfileManager.shared.generateNutritionTargets(apiKey: apiKey)
                print("✓ Nutrition targets generated successfully")
            } catch {
                print("⚠️ Failed to generate nutrition targets: \(error.localizedDescription)")
                // Don't block user flow if this fails
            }
        }

        dismiss()
        onFinished?()
    }

    private func resetProfile() {
        UserProfileManager.shared.clearProfile()
        UserProfileManager.shared.setOnboardingNeeded(true)

        // Delete API key
        try? GeminiConfiguration.deleteAPIKey()

        // Delete all SwiftData database files
        deleteAllSwiftDataDatabases()

        let profile = UserProfileManager.shared.defaultProfile()
        name = "Welcome"
        selected = []
        weightValue = Int(profile.weight)
        heightValue = Int(profile.height)
        age = profile.age
        genderValue = profile.gender.lowercased() == "female" ? 1.0 : 0.0
        if let idx = activityOptionsData.firstIndex(where: { $0.title == profile.activityLevel }) {
            activityLevelIndex = idx
        }
        dietPreference = ""
        otherNotes = ""
        BMI = CalculateBMI(weight: Int(profile.weight), height: Int(profile.height))
    }

    private func deleteAllSwiftDataDatabases() {
        let documentsURL = URL.documentsDirectory
        let fileManager = FileManager.default

        // List of all SwiftData database files
        let databaseFiles = [
            "default.store",
            "default.store-shm",
            "default.store-wal",
            "MealHistory.sqlite",
            "MealHistory.sqlite-shm",
            "MealHistory.sqlite-wal",
            "Trophies.sqlite",
            "Trophies.sqlite-shm",
            "Trophies.sqlite-wal"
        ]

        for filename in databaseFiles {
            let fileURL = documentsURL.appending(path: filename)
            try? fileManager.removeItem(at: fileURL)
            print("🗑️ Deleted: \(filename)")
        }

        print("✓ All SwiftData databases deleted")
    }

    private func generateTestData() {
        print("🧪 Generating test data...")

        // 1. Create test user profile
        let testProfile = UserNutritionProfile(
            name: "Test User",
            weight: 70.0,
            height: 175.0,
            age: 28,
            gender: "Male",
            activityLevel: "Moderately Active",
            goals: ["Build Muscle", "General Fitness"],
            preference: "No restrictions",
            other: "Test user for demonstration"
        )
        UserProfileManager.shared.saveProfile(testProfile)

        // Update UI fields to reflect test profile
        name = testProfile.name
        weightValue = Int(testProfile.weight)
        heightValue = Int(testProfile.height)
        age = testProfile.age
        genderValue = testProfile.gender.lowercased() == "female" ? 1.0 : 0.0
        if let idx = activityOptionsData.firstIndex(where: { $0.title == testProfile.activityLevel }) {
            activityLevelIndex = idx
        }
        selected = testProfile.goals
        dietPreference = testProfile.preference
        otherNotes = testProfile.other
        BMI = CalculateBMI(weight: Int(testProfile.weight), height: Int(testProfile.height))

        // 2. Generate nutrition targets
        Task {
            do {
                if let apiKey = GeminiConfiguration.apiKey {
                    try await UserProfileManager.shared.generateNutritionTargets(apiKey: apiKey)
                    print("✓ Test nutrition targets generated")
                }
            } catch {
                print("⚠️ Could not generate nutrition targets: \(error)")
            }

            // 3. Generate test meals for past 10 days
            await generateTestMeals()

            // 4. Generate test trophies
            generateTestTrophies()

            print("✓ Test data generation complete!")
        }
    }

    private func generateTestMeals() async {
        let calendar = Calendar.current
        let now = Date()

        // Sample dishes data
        let breakfastDishes = [
            ("Oatmeal with Berries", "🥣", [
                ("Oats", "🌾", 50.0, 13.0, 7.0, 68.0),
                ("Blueberries", "🫐", 100.0, 1.0, 0.3, 14.0),
                ("Milk", "🥛", 200.0, 7.0, 8.0, 12.0)
            ]),
            ("Scrambled Eggs & Toast", "🍳", [
                ("Eggs", "🥚", 120.0, 76.0, 10.0, 2.0),
                ("Whole Wheat Bread", "🍞", 60.0, 15.0, 3.0, 52.0),
                ("Butter", "🧈", 10.0, 1.0, 82.0, 0.1)
            ])
        ]

        let lunchDishes = [
            ("Grilled Chicken Salad", "🥗", [
                ("Chicken Breast", "🍗", 150.0, 80.0, 5.0, 0.0),
                ("Mixed Greens", "🥬", 100.0, 3.0, 0.5, 7.0),
                ("Olive Oil", "🫒", 15.0, 0.0, 100.0, 0.0)
            ]),
            ("Salmon Rice Bowl", "🍚", [
                ("Salmon", "🐟", 150.0, 68.0, 13.0, 0.0),
                ("Brown Rice", "🍚", 150.0, 8.0, 2.0, 77.0),
                ("Vegetables", "🥦", 100.0, 3.0, 0.4, 7.0)
            ])
        ]

        let dinnerDishes = [
            ("Beef Stir-Fry", "🍜", [
                ("Beef", "🥩", 150.0, 70.0, 20.0, 0.0),
                ("Vegetables", "🥕", 150.0, 2.0, 0.3, 9.0),
                ("Noodles", "🍝", 100.0, 13.0, 2.0, 75.0)
            ]),
            ("Pasta Bolognese", "🍝", [
                ("Pasta", "🍝", 150.0, 13.0, 2.0, 75.0),
                ("Beef Sauce", "🥩", 120.0, 60.0, 15.0, 5.0),
                ("Cheese", "🧀", 30.0, 25.0, 33.0, 1.0)
            ])
        ]

        // Generate meals for past 10 days
        for dayOffset in 0..<10 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

            // Breakfast
            let breakfast = breakfastDishes.randomElement()!
            let breakfastTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
            try? await saveMeal(dishes: [breakfast], mealType: .breakfast, timestamp: breakfastTime)

            // Lunch
            let lunch = lunchDishes.randomElement()!
            let lunchTime = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: date)!
            try? await saveMeal(dishes: [lunch], mealType: .lunch, timestamp: lunchTime)

            // Dinner
            let dinner = dinnerDishes.randomElement()!
            let dinnerTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date)!
            try? await saveMeal(dishes: [dinner], mealType: .dinner, timestamp: dinnerTime)
        }

        print("✓ Generated test meals for 10 days")
    }

    private func saveMeal(
        dishes: [(String, String, [(String, String, Double, Double, Double, Double)])],
        mealType: MealType,
        timestamp: Date
    ) async throws {
        let dishModels = dishes.map { dishData in
            let (dishName, dishIcon, ingredientsData) = dishData
            let ingredients = ingredientsData.map { ingredientData in
                let (name, icon, weight, protein, fat, carb) = ingredientData
                return FoodIngredient(
                    name: name,
                    icon: icon,
                    weight: weight,
                    proteinPercent: protein,
                    fatPercent: fat,
                    carbohydratePercent: carb
                )
            }
            return Dish(name: dishName, icon: dishIcon, ingredients: ingredients)
        }

        try MealPersistenceManager.shared.saveMeal(
            timestamp: timestamp,
            mealType: mealType,
            photo: nil,
            dishes: dishModels,
            dietaryAdvice: nil
        )
    }

    private func generateTestTrophies() {
        // Generate some test trophies
        let calendar = Calendar.current
        let now = Date()

        // Single day trophies for last 7 days
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let trophy = Trophy(
                id: UUID(),
                type: .singleDay,
                earnedDate: date,
                streakDays: 1,
                calories: 2000,
                protein: 150,
                fat: 60,
                carbohydrate: 200
            )
            saveTrophyDirectly(trophy)
        }

        // 3-day streak trophies
        for i in 0..<2 {
            guard let date = calendar.date(byAdding: .day, value: -i * 3, to: now) else { continue }
            let trophy = Trophy(
                id: UUID(),
                type: .threeDay,
                earnedDate: date,
                streakDays: 3,
                calories: 2050,
                protein: 155,
                fat: 62,
                carbohydrate: 205
            )
            saveTrophyDirectly(trophy)
        }

        // 7-day streak trophy
        let sevenDayTrophy = Trophy(
            id: UUID(),
            type: .sevenDay,
            earnedDate: now,
            streakDays: 7,
            calories: 2000,
            protein: 150,
            fat: 60,
            carbohydrate: 200
        )
        saveTrophyDirectly(sevenDayTrophy)

        print("✓ Generated test trophies")
    }

    private func saveTrophyDirectly(_ trophy: Trophy) {
        TrophyManager.shared.saveTrophyDirectly(trophy)
    }
}

// Custom styled text field
struct CustomTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .fontDesign(.serif)
                .fontWeight(.bold)
                .foregroundStyle(.mainText)
            
            // 使用下划线风格 (Typewriter style aesthetic)
            VStack(spacing: 0) {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, design: .serif))
                    .padding(.vertical, 8)
                    .foregroundStyle(.userEnable)
            }
        }
    }
}

#Preview {
    InfoView()
}
