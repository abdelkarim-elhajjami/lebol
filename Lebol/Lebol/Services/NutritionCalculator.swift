import Foundation

struct NutritionCalculator {

    // MARK: - Unit Conversion Constants
    static let kgToLbs = 2.20462
    static let lbsToKg = 1.0 / 2.20462

    // MARK: - BMR (Mifflin-St Jeor Equation, 1990)
    // Citation: Mifflin MD, St Jeor ST, et al. Am J Clin Nutr, 1990;51(2):241-247. PMID: 2305711
    // Male:   BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
    // Female: BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161

    static func calculateBMR(weightKg: Double, heightCm: Double, age: Int, gender: Gender) -> Double {
        switch gender {
        case .male:
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        case .female:
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
    }

    // MARK: - TDEE (Sedentary baseline, PAL 1.55)
    // Citation: FAO/WHO/UNU. "Human Energy Requirements." FAO Food and Nutrition Technical Report Series No. 1, Rome, 2004.
    // Midpoint of FAO sedentary range (1.40–1.69). Accounts for NEAT (daily movement, household tasks).
    // Extra activity logged daily via MET-based calculations, not baked into TDEE.

    static let sedentaryPAL = 1.55

    static func calculateTDEE(bmr: Double) -> Double {
        return bmr * sedentaryPAL
    }

    // MARK: - Daily Calorie Goal
    // Daily Goal = TDEE - (weekly_kg × 1100)
    // 7700 kcal per kg of body fat (Wishnofsky, 1958; Hall KD, Int J Obesity, 2008)
    // Safety floors: 1500 kcal (male), 1200 kcal (female) — NIH/NHLBI

    static func calculateDailyCalories(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: Gender,
        weeklyGoalGrams: Int
    ) -> Int {
        let bmr = calculateBMR(weightKg: weightKg, heightCm: heightCm, age: age, gender: gender)
        let tdee = calculateTDEE(bmr: bmr)

        // Maintenance mode: no deficit when weeklyGoalGrams is 0
        guard weeklyGoalGrams > 0 else { return Int(tdee) }

        // Daily deficit from weekly loss goal: weekly_kg × 1100
        let weeklyKg = Double(weeklyGoalGrams) / 1000.0
        let dailyDeficit = weeklyKg * 1100.0

        let dailyCalories = tdee - dailyDeficit

        // Safety floor
        let minimum: Double = gender == .male ? 1500 : 1200
        return Int(max(dailyCalories, minimum))
    }

    // MARK: - Macronutrient Calculation (Body-Weight-Based Protein)
    // Protein: 1.6 g/kg body weight (Morton et al., Br J Sports Med, 2018; ISSN Position Stand, 2017)
    // Fat: 25% of calories (within IOM AMDR 20-35%)
    // Carbs: remainder
    // Atwater factors: Carbs 4 kcal/g, Protein 4 kcal/g, Fat 9 kcal/g

    static func calculateMacros(dailyCalories: Int, weightKg: Double) -> (carbs: Int, protein: Int, fats: Int) {
        // Protein: 1.6 g/kg, capped at 35% of calories
        var proteinG = weightKg * 1.6
        let maxProteinCal = Double(dailyCalories) * 0.35
        if proteinG * 4 > maxProteinCal {
            proteinG = maxProteinCal / 4
        }

        // Fat: 25% of calories
        let fatG = Double(dailyCalories) * 0.25 / 9

        // Carbs: remainder
        let carbCal = Double(dailyCalories) - (proteinG * 4) - (fatG * 9)
        let carbG = max(carbCal / 4, 0)

        return (carbs: Int(carbG), protein: Int(proteinG), fats: Int(fatG))
    }

    // MARK: - Target Weight Recommendation (BMI 22.0 midpoint)
    // Citation: WHO BMI classification. Healthy range 18.5–24.9, midpoint 22.0

    static func recommendedTargetWeight(heightCm: Double) -> Double {
        let heightM = heightCm / 100.0
        return (22.0 * heightM * heightM).rounded()
    }

    static func bmi(weightKg: Double, heightCm: Double) -> Double {
        let heightM = heightCm / 100.0
        guard heightM > 0 else { return 0 }
        return weightKg / (heightM * heightM)
    }

    // MARK: - Goal Date
    // weeks_to_goal = (current - target) / weekly_rate
    // goal_date = today + ceil(weeks_to_goal) weeks

    static func estimateGoalDate(
        currentWeight: Double,
        targetWeight: Double,
        weeklyGoalGrams: Int
    ) -> Date {
        let totalToLose = currentWeight - targetWeight
        guard totalToLose > 0, weeklyGoalGrams > 0 else { return Date() }

        let weeklyKg = Double(weeklyGoalGrams) / 1000.0
        let weeksNeeded = ceil(totalToLose / weeklyKg)
        let daysNeeded = Int(weeksNeeded * 7)

        return Calendar.current.date(byAdding: .day, value: daysNeeded, to: Date()) ?? Date()
    }

    // MARK: - Activity Calories (MET-based)
    // Citation: Ainsworth BE, et al. Med Sci Sports Exerc, 2011;43(8):1575-1581. PMID: 21681120
    // Calories = MET × weight_kg × duration_hours

    static func calculateActivityCalories(met: Double, weightKg: Double, durationMinutes: Int) -> Int {
        let durationHours = Double(durationMinutes) / 60.0
        let calories = met * weightKg * durationHours
        return max(Int(calories), 0)
    }

    // MARK: - Hydration Goal
    // Clinical approximation: weight_kg × 33 ml, rounded to nearest 100 ml
    // Citation: EFSA recommends 2.5 L/day (men), 2.0 L/day (women)

    static func calculateWaterGoal(weightKg: Double) -> Int {
        let raw = weightKg * 33
        return Int((raw / 100).rounded()) * 100
    }

    // MARK: - Safety Validation

    static func isTargetWeightValid(targetKg: Double, currentKg: Double, heightCm: Double) -> (valid: Bool, reason: String?) {
        if targetKg >= currentKg {
            return (false, "Target must be less than current weight")
        }
        let targetBMI = bmi(weightKg: targetKg, heightCm: heightCm)
        if targetBMI < 18.5 {
            return (false, "Target weight would put you below healthy BMI range")
        }
        if targetKg < 40 {
            return (false, "Target weight must be at least 40 kg")
        }
        return (true, nil)
    }

}
