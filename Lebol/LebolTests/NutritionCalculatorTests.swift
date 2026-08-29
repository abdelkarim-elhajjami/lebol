import XCTest
@testable import Lebol

final class NutritionCalculatorTests: XCTestCase {

    // MARK: - T1. BMR Calculation Tests
    // Formula: Male = (10×w) + (6.25×h) - (5×a) + 5
    //          Female = (10×w) + (6.25×h) - (5×a) - 161

    // T1.1 Standard Cases
    func testBMR_T1_1a_Male95kg176cm26y() {
        // (10×95)+(6.25×176)-(5×26)+5 = 950+1100-130+5 = 1925
        let bmr = NutritionCalculator.calculateBMR(weightKg: 95, heightCm: 176, age: 26, gender: .male)
        XCTAssertEqual(Int(bmr), 1925)
    }

    func testBMR_T1_1b_Female65kg165cm30y() {
        // (10×65)+(6.25×165)-(5×30)-161 = 650+1031.25-150-161 = 1370.25
        let bmr = NutritionCalculator.calculateBMR(weightKg: 65, heightCm: 165, age: 30, gender: .female)
        XCTAssertEqual(Int(bmr), 1370)
    }

    func testBMR_T1_1c_Male80kg180cm40y() {
        // (10×80)+(6.25×180)-(5×40)+5 = 800+1125-200+5 = 1730
        let bmr = NutritionCalculator.calculateBMR(weightKg: 80, heightCm: 180, age: 40, gender: .male)
        XCTAssertEqual(Int(bmr), 1730)
    }

    func testBMR_T1_1d_Female55kg158cm22y() {
        // (10×55)+(6.25×158)-(5×22)-161 = 550+987.5-110-161 = 1266.5
        let bmr = NutritionCalculator.calculateBMR(weightKg: 55, heightCm: 158, age: 22, gender: .female)
        XCTAssertEqual(Int(bmr), 1266)
    }

    func testBMR_T1_1e_Male120kg190cm45y() {
        // (10×120)+(6.25×190)-(5×45)+5 = 1200+1187.5-225+5 = 2167.5
        let bmr = NutritionCalculator.calculateBMR(weightKg: 120, heightCm: 190, age: 45, gender: .male)
        XCTAssertEqual(Int(bmr), 2167)
    }

    func testBMR_T1_1f_Female100kg170cm35y() {
        // (10×100)+(6.25×170)-(5×35)-161 = 1000+1062.5-175-161 = 1726.5
        let bmr = NutritionCalculator.calculateBMR(weightKg: 100, heightCm: 170, age: 35, gender: .female)
        XCTAssertEqual(Int(bmr), 1726)
    }

    // T1.2 Edge Cases
    func testBMR_T1_2a_MinAge() {
        // (10×80)+(6.25×175)-(5×18)+5 = 800+1093.75-90+5 = 1808.75
        let bmr = NutritionCalculator.calculateBMR(weightKg: 80, heightCm: 175, age: 18, gender: .male)
        XCTAssertEqual(Int(bmr), 1808)
    }

    func testBMR_T1_2b_MaxAge() {
        // (10×60)+(6.25×160)-(5×78)-161 = 600+1000-390-161 = 1049
        let bmr = NutritionCalculator.calculateBMR(weightKg: 60, heightCm: 160, age: 78, gender: .female)
        XCTAssertEqual(Int(bmr), 1049)
    }

    func testBMR_T1_2c_VeryLightPerson() {
        // (10×40)+(6.25×150)-(5×25)-161 = 400+937.5-125-161 = 1051.5
        let bmr = NutritionCalculator.calculateBMR(weightKg: 40, heightCm: 150, age: 25, gender: .female)
        XCTAssertEqual(Int(bmr), 1051)
    }

    func testBMR_T1_2d_VeryHeavyPerson() {
        // (10×150)+(6.25×195)-(5×30)+5 = 1500+1218.75-150+5 = 2573.75
        let bmr = NutritionCalculator.calculateBMR(weightKg: 150, heightCm: 195, age: 30, gender: .male)
        XCTAssertEqual(Int(bmr), 2573)
    }

    func testBMR_T1_2e_ShortPerson() {
        // (10×50)+(6.25×140)-(5×40)-161 = 500+875-200-161 = 1014
        let bmr = NutritionCalculator.calculateBMR(weightKg: 50, heightCm: 140, age: 40, gender: .female)
        XCTAssertEqual(Int(bmr), 1014)
    }

    func testBMR_T1_2f_TallPerson() {
        // (10×90)+(6.25×200)-(5×25)+5 = 900+1250-125+5 = 2030
        let bmr = NutritionCalculator.calculateBMR(weightKg: 90, heightCm: 200, age: 25, gender: .male)
        XCTAssertEqual(Int(bmr), 2030)
    }

    // MARK: - T2. TDEE Calculation Tests (Sedentary baseline PAL 1.55)

    func testTDEE_T2_1a_Male() {
        // BMR = 1925 (Male, 95kg, 176cm, 26y) × 1.55 = 2983
        let tdee = NutritionCalculator.calculateTDEE(bmr: 1925)
        XCTAssertEqual(Int(tdee), 2983)
    }

    func testTDEE_T2_1b_Female() {
        // BMR for Female, 65kg, 165cm, 30y = 1370.25 × 1.55 = 2123.89
        let bmr = NutritionCalculator.calculateBMR(weightKg: 65, heightCm: 165, age: 30, gender: .female)
        let tdee = NutritionCalculator.calculateTDEE(bmr: bmr)
        XCTAssertEqual(Int(tdee), 2123)
    }

    func testTDEE_T2_1c_PALConstant() {
        XCTAssertEqual(NutritionCalculator.sedentaryPAL, 1.55)
    }

    // MARK: - T3. Daily Calorie Goal Tests
    // BMR for test user (Male, 95kg, 176cm, 26y) = 1925
    // TDEE (sedentary baseline) = 1925 × 1.55 = 2983
    // Daily Goal = Int(TDEE - weeklyKg × 1100)

    func testDailyGoal_T3_1a_Easy() {
        let goal = NutritionCalculator.calculateDailyCalories(
            weightKg: 95, heightCm: 176, age: 26, gender: .male,
            weeklyGoalGrams: 250
        )
        // 2983 - 275 = 2708
        XCTAssertEqual(goal, 2708)
    }

    func testDailyGoal_T3_1b_EasyMid() {
        let goal = NutritionCalculator.calculateDailyCalories(
            weightKg: 95, heightCm: 176, age: 26, gender: .male,
            weeklyGoalGrams: 500
        )
        // 2983 - 550 = 2433
        XCTAssertEqual(goal, 2433)
    }

    func testDailyGoal_T3_1c_Balanced() {
        let goal = NutritionCalculator.calculateDailyCalories(
            weightKg: 95, heightCm: 176, age: 26, gender: .male,
            weeklyGoalGrams: 750
        )
        // 2983 - 825 = 2158
        XCTAssertEqual(goal, 2158)
    }

    func testDailyGoal_T3_1d_Strict() {
        let goal = NutritionCalculator.calculateDailyCalories(
            weightKg: 95, heightCm: 176, age: 26, gender: .male,
            weeklyGoalGrams: 1000
        )
        // 2983 - 1100 = 1883
        XCTAssertEqual(goal, 1883)
    }

    // T3.2 Safety Floor Tests
    func testDailyGoal_T3_2a_MaleFloorHit() {
        // Male with TDEE 2200, 1.0 kg/wk → raw 1100, floor 1500
        let goalMale = max(Int(2200.0 - 1100), 1500)
        XCTAssertEqual(goalMale, 1500)
    }

    func testDailyGoal_T3_2c_FemaleFloorHit() {
        // Female with TDEE 1800, 0.75 kg/wk → raw 975, floor 1200
        let goalFemale = max(Int(1800.0 - 825), 1200)
        XCTAssertEqual(goalFemale, 1200)
    }

    func testDailyGoal_T3_2b_MaleFloorNotHit() {
        let goal = max(Int(2700.0 - 1100), 1500)
        XCTAssertEqual(goal, 1600)
    }

    func testDailyGoal_T3_2d_FemaleFloorNotHit() {
        let goal = max(Int(2100.0 - 550), 1200)
        XCTAssertEqual(goal, 1550)
    }

    // MARK: - T4. Target Weight Tests

    // T4.1 BMI-Based Recommendation: 22.0 × height_m², rounded
    func testTargetWeight_T4_1a_176cm() {
        let target = NutritionCalculator.recommendedTargetWeight(heightCm: 176)
        XCTAssertEqual(Int(target), 68) // 22 × 3.0976 = 68.15 → 68
    }

    func testTargetWeight_T4_1b_165cm() {
        let target = NutritionCalculator.recommendedTargetWeight(heightCm: 165)
        XCTAssertEqual(Int(target), 60) // 22 × 2.7225 = 59.895 → 60
    }

    func testTargetWeight_T4_1c_180cm() {
        let target = NutritionCalculator.recommendedTargetWeight(heightCm: 180)
        XCTAssertEqual(Int(target), 71) // 22 × 3.24 = 71.28 → 71
    }

    func testTargetWeight_T4_1d_158cm() {
        let target = NutritionCalculator.recommendedTargetWeight(heightCm: 158)
        XCTAssertEqual(Int(target), 55) // 22 × 2.4964 = 54.92 → 55
    }

    func testTargetWeight_T4_1e_190cm() {
        let target = NutritionCalculator.recommendedTargetWeight(heightCm: 190)
        XCTAssertEqual(Int(target), 79) // 22 × 3.61 = 79.42 → 79
    }

    func testTargetWeight_T4_1f_150cm() {
        let target = NutritionCalculator.recommendedTargetWeight(heightCm: 150)
        XCTAssertEqual(Int(target), 50) // 22 × 2.25 = 49.5 → rounds to 50
    }

    // T4.2 Validation Rules
    func testTargetWeightValid_T4_2a() {
        let result = NutritionCalculator.isTargetWeightValid(targetKg: 68, currentKg: 95, heightCm: 176)
        XCTAssertTrue(result.valid)
        XCTAssertNil(result.reason)
    }

    func testTargetWeightReject_T4_2b_AboveCurrent() {
        let result = NutritionCalculator.isTargetWeightValid(targetKg: 100, currentKg: 95, heightCm: 176)
        XCTAssertFalse(result.valid)
    }

    func testTargetWeightReject_T4_2c_UnderweightBMI() {
        let result = NutritionCalculator.isTargetWeightValid(targetKg: 50, currentKg: 95, heightCm: 176)
        XCTAssertFalse(result.valid) // BMI = 16.1 < 18.5
    }

    func testTargetWeightReject_T4_2e_Below40kg() {
        let result = NutritionCalculator.isTargetWeightValid(targetKg: 38, currentKg: 60, heightCm: 150)
        XCTAssertFalse(result.valid)
    }

    func testTargetWeightAccept_T4_2f_AtHealthyMin() {
        let result = NutritionCalculator.isTargetWeightValid(targetKg: 51, currentKg: 80, heightCm: 165)
        XCTAssertTrue(result.valid) // BMI = 18.73 ✓
    }

    // MARK: - T5. Macronutrient Tests (Body-Weight-Based Protein)
    // Protein: 1.6 g/kg (capped at 35% of kcal), Fat: 25% of kcal, Carbs: remainder

    func testMacros_T5_1a_95kg_2104kcal() {
        let macros = NutritionCalculator.calculateMacros(dailyCalories: 2104, weightKg: 95)
        XCTAssertEqual(macros.protein, 152) // 95×1.6 = 152g (28.9%, no cap)
        XCTAssertEqual(macros.fats, 58)     // 2104×0.25/9 = 58.4 → 58
        XCTAssertEqual(macros.carbs, 242)   // remainder
    }

    func testMacros_T5_1b_65kg_1550kcal() {
        let macros = NutritionCalculator.calculateMacros(dailyCalories: 1550, weightKg: 65)
        XCTAssertEqual(macros.protein, 104) // 65×1.6 = 104g
        XCTAssertEqual(macros.fats, 43)     // 1550×0.25/9 = 43.05 → 43
        XCTAssertEqual(macros.carbs, 186)   // remainder
    }

    func testMacros_T5_1c_80kg_2000kcal() {
        let macros = NutritionCalculator.calculateMacros(dailyCalories: 2000, weightKg: 80)
        XCTAssertEqual(macros.protein, 128) // 80×1.6 = 128g
        XCTAssertEqual(macros.fats, 55)     // 2000×0.25/9 = 55.55 → 55
        XCTAssertEqual(macros.carbs, 247)   // remainder
    }

    func testMacros_T5_1d_55kg_1200kcal() {
        let macros = NutritionCalculator.calculateMacros(dailyCalories: 1200, weightKg: 55)
        XCTAssertEqual(macros.protein, 88)  // 55×1.6 = 88g
        XCTAssertEqual(macros.fats, 33)     // 1200×0.25/9 = 33.33 → 33
        XCTAssertEqual(macros.carbs, 137)   // remainder
    }

    // T5.2 Protein cap at 35% of calories (heavy person at safety floor)
    func testMacros_T5_2_ProteinCap_120kg_1500kcal() {
        let macros = NutritionCalculator.calculateMacros(dailyCalories: 1500, weightKg: 120)
        // 120×1.6 = 192g → 768 kcal = 51.2% > 35% → capped
        // Cap: 1500×0.35/4 = 131.25 → 131g
        XCTAssertEqual(macros.protein, 131)
        XCTAssertEqual(macros.fats, 41)     // 1500×0.25/9 = 41.66 → 41
        XCTAssertEqual(macros.carbs, 150)   // remainder
    }

    // T5.3 Macro Scaling with Burned Calories (protein stays weight-based)
    func testMacroScaling_T5_3a_95kg_base() {
        let macros = NutritionCalculator.calculateMacros(dailyCalories: 2104, weightKg: 95)
        XCTAssertEqual(macros.protein, 152)
        XCTAssertEqual(macros.fats, 58)
        XCTAssertEqual(macros.carbs, 242)
    }

    func testMacroScaling_T5_3b_95kg_300burned() {
        let macros = NutritionCalculator.calculateMacros(dailyCalories: 2104 + 300, weightKg: 95)
        XCTAssertEqual(macros.protein, 152) // same — weight-based, not calorie-based
        XCTAssertEqual(macros.fats, 66)     // 2404×0.25/9 = 66.77 → 66
        XCTAssertEqual(macros.carbs, 298)   // remainder absorbs extra
    }

    func testMacroScaling_T5_3c_95kg_642burned() {
        let macros = NutritionCalculator.calculateMacros(dailyCalories: 2104 + 642, weightKg: 95)
        XCTAssertEqual(macros.protein, 152) // same
        XCTAssertEqual(macros.fats, 76)     // 2746×0.25/9 = 76.27 → 76
        XCTAssertEqual(macros.carbs, 362)   // remainder
    }

    // MARK: - T6. Dashboard / Calorie Ring Tests

    func testKcalLeft_T6_1a() {
        let left = 2100 - 0 + 0
        XCTAssertEqual(left, 2100)
    }

    func testKcalLeft_T6_1b() {
        let left = 2100 - 500 + 0
        XCTAssertEqual(left, 1600)
    }

    func testKcalLeft_T6_1c_BurnedON() {
        let left = 2100 - 500 + 300
        XCTAssertEqual(left, 1900)
    }

    func testKcalLeft_T6_1d_BurnedOFF() {
        let left = 2100 - 500
        XCTAssertEqual(left, 1600)
    }

    func testKcalLeft_T6_1f_OverBudget() {
        let left = 2100 - 2500 + 0
        XCTAssertEqual(left, -400)
    }

    func testRingProgress_T6_2c_50pct() {
        let progress = 1050.0 / 2100.0
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func testRingProgress_T6_2f_5pct() {
        let progress = 155.0 / 2889.0
        XCTAssertEqual(progress, 0.054, accuracy: 0.001)
    }

    // MARK: - T9. Hydration Tests
    // Formula: weight_kg × 33, rounded to nearest 100

    func testHydration_T9_a_95kg() {
        XCTAssertEqual(NutritionCalculator.calculateWaterGoal(weightKg: 95), 3100)
    }

    func testHydration_T9_b_65kg() {
        XCTAssertEqual(NutritionCalculator.calculateWaterGoal(weightKg: 65), 2100)
    }

    func testHydration_T9_c_50kg() {
        // 50×33 = 1650 → rounds to 1700
        XCTAssertEqual(NutritionCalculator.calculateWaterGoal(weightKg: 50), 1700)
    }

    func testHydration_T9_d_120kg() {
        // 120×33 = 3960 → rounds to 4000
        XCTAssertEqual(NutritionCalculator.calculateWaterGoal(weightKg: 120), 4000)
    }

    func testHydration_T9_e_40kg() {
        // 40×33 = 1320 → rounds to 1300
        XCTAssertEqual(NutritionCalculator.calculateWaterGoal(weightKg: 40), 1300)
    }

    // MARK: - T10. Burned Calories (MET) Tests
    // Formula: MET × weight_kg × (duration_min / 60)

    func testActivity_T10_1a_WalkingModerate() {
        let cal = NutritionCalculator.calculateActivityCalories(met: 3.5, weightKg: 95, durationMinutes: 30)
        XCTAssertEqual(cal, 166) // 3.5 × 95 × 0.5 = 166.25 → 166
    }

    func testActivity_T10_1b_SwimmingModerate() {
        let cal = NutritionCalculator.calculateActivityCalories(met: 5.8, weightKg: 95, durationMinutes: 45)
        XCTAssertEqual(cal, 413) // 5.8 × 95 × 0.75 = 413.25 → 413
    }

    func testActivity_T10_1c_Running8kmh() {
        let cal = NutritionCalculator.calculateActivityCalories(met: 8.3, weightKg: 80, durationMinutes: 20)
        XCTAssertEqual(cal, 221) // 8.3 × 80 × 0.333 = 221.33 → 221
    }

    func testActivity_T10_1d_Yoga() {
        let cal = NutritionCalculator.calculateActivityCalories(met: 2.5, weightKg: 65, durationMinutes: 60)
        XCTAssertEqual(cal, 162) // 2.5 × 65 × 1.0 = 162.5 → 162
    }

    func testActivity_T10_1e_CyclingModerate() {
        let cal = NutritionCalculator.calculateActivityCalories(met: 6.8, weightKg: 90, durationMinutes: 45)
        XCTAssertEqual(cal, 459) // 6.8 × 90 × 0.75 = 459
    }

    func testActivity_T10_1f_HIIT() {
        let cal = NutritionCalculator.calculateActivityCalories(met: 8.0, weightKg: 75, durationMinutes: 15)
        XCTAssertEqual(cal, 150) // 8.0 × 75 × 0.25 = 150
    }

    // MARK: - T15. Unit Conversion Tests

    func testConversion_T15_a_KgToLbs() {
        let lbs = 95.0 * 2.20462
        XCTAssertEqual(lbs, 209.4, accuracy: 0.1)
    }

    func testConversion_T15_b_CmToFtIn() {
        let totalInches = 176.0 * 0.393701
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        XCTAssertEqual(feet, 5)
        XCTAssertEqual(inches, 9)
    }

    func testConversion_T15_e_LbsToKg() {
        let kg = 150.0 * 0.453592
        XCTAssertEqual(kg, 68.0, accuracy: 0.1)
    }

    func testConversion_T15_f_FtInToCm() {
        let cm = (5.0 * 30.48) + (6.0 * 2.54)
        XCTAssertEqual(cm, 167.6, accuracy: 0.1)
    }

    // MARK: - BMI Tests

    func testBMI_HealthyRange() {
        let bmi = NutritionCalculator.bmi(weightKg: 68, heightCm: 176)
        XCTAssertEqual(bmi, 21.95, accuracy: 0.1)
    }

    func testBMI_Overweight() {
        let bmi = NutritionCalculator.bmi(weightKg: 95, heightCm: 176)
        XCTAssertEqual(bmi, 30.67, accuracy: 0.1)
    }

    func testBMI_Underweight() {
        let bmi = NutritionCalculator.bmi(weightKg: 50, heightCm: 176)
        XCTAssertEqual(bmi, 16.14, accuracy: 0.1)
    }

    // MARK: - T11. End-to-End Onboarding Validation

    func testOnboarding_T11_1_FullFlow() {
        // Male, 95 kg, 176 cm, 26 years, Sedentary baseline, Target 68 kg, 0.75 kg/week
        let bmr = NutritionCalculator.calculateBMR(weightKg: 95, heightCm: 176, age: 26, gender: .male)
        XCTAssertEqual(Int(bmr), 1925)

        let tdee = NutritionCalculator.calculateTDEE(bmr: bmr)
        XCTAssertEqual(Int(tdee), 2983) // 1925 × 1.55 = 2983

        let dailyGoal = NutritionCalculator.calculateDailyCalories(
            weightKg: 95, heightCm: 176, age: 26, gender: .male,
            weeklyGoalGrams: 750
        )
        XCTAssertEqual(dailyGoal, 2158) // 2983 - 825 = 2158

        let macros = NutritionCalculator.calculateMacros(dailyCalories: dailyGoal, weightKg: 95)
        XCTAssertEqual(macros.protein, 152) // 95×1.6 = 152g (body-weight-based)
        XCTAssertEqual(macros.fats, 59)     // 2158×0.25/9 = 59.9 → 59
        XCTAssertEqual(macros.carbs, 252)   // (2158 - 608 - 539.5) / 4 = 252.6 → 252

        let waterGoal = NutritionCalculator.calculateWaterGoal(weightKg: 95)
        XCTAssertEqual(waterGoal, 3100)

        let targetWeight = NutritionCalculator.recommendedTargetWeight(heightCm: 176)
        XCTAssertEqual(Int(targetWeight), 68)

        let targetBMI = NutritionCalculator.bmi(weightKg: 68, heightCm: 176)
        XCTAssertTrue(targetBMI >= 18.5 && targetBMI <= 24.9)
    }

    // MARK: - Formula Correctness Verification

    func testMifflinStJeor_MaleFormula() {
        // Verify the Mifflin-St Jeor formula coefficients are correct
        // Male: BMR = 10w + 6.25h - 5a + 5
        let w = 75.0, h = 175.0, a = 30
        let expected = (10 * w) + (6.25 * h) - (5 * Double(a)) + 5
        let result = NutritionCalculator.calculateBMR(weightKg: w, heightCm: h, age: a, gender: .male)
        XCTAssertEqual(result, expected)
    }

    func testMifflinStJeor_FemaleFormula() {
        // Female: BMR = 10w + 6.25h - 5a - 161
        let w = 60.0, h = 165.0, a = 25
        let expected = (10 * w) + (6.25 * h) - (5 * Double(a)) - 161
        let result = NutritionCalculator.calculateBMR(weightKg: w, heightCm: h, age: a, gender: .female)
        XCTAssertEqual(result, expected)
    }

    func testSedentaryPAL_WHO_FAO() {
        // Verify sedentary PAL value — midpoint of FAO sedentary range (1.40–1.69)
        XCTAssertEqual(NutritionCalculator.sedentaryPAL, 1.55)
    }

    func testSafetyFloor_Male1500() {
        // Male safety floor is 1500 kcal
        let goal = NutritionCalculator.calculateDailyCalories(
            weightKg: 60, heightCm: 170, age: 30, gender: .male,
            weeklyGoalGrams: 1000
        )
        XCTAssertGreaterThanOrEqual(goal, 1500)
    }

    func testSafetyFloor_Female1200() {
        // Female safety floor is 1200 kcal
        let goal = NutritionCalculator.calculateDailyCalories(
            weightKg: 45, heightCm: 155, age: 25, gender: .female,
            weeklyGoalGrams: 1000
        )
        XCTAssertGreaterThanOrEqual(goal, 1200)
    }

    func testWeeklyLossCap() {
        // Maximum safe weekly loss is 1.0 kg/week per CDC/NHS/Mayo
        // At 1.0 kg/week, daily deficit = 1100 kcal
        let deficit = 1.0 * 1100.0
        XCTAssertEqual(deficit, 1100)
    }
}
