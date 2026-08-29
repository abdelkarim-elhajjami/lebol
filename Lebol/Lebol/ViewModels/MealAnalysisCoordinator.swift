import Foundation
import UIKit

// MARK: - Shared coordinator for AI food analysis → MealReviewView navigation

@MainActor @Observable
final class MealAnalysisCoordinator {
    var reviewItems: [ReviewableFoodItem] = []
    var reviewMealName = ""
    var showingReview = false
    var isAnalyzing = false
    var errorMessage: String?
    var analysisProgress = ""

    private let service: FoodAnalysisService

    init(service: FoodAnalysisService = GeminiService.shared) {
        self.service = service
    }

    func analyzeText(_ text: String) async {
        guard !text.isEmpty else { return }

        isAnalyzing = true
        errorMessage = nil

        do {
            let result = try await service.analyzeTextStructured(text)
            reviewMealName = result.mealName
            reviewItems = result.ingredients.map { ReviewableFoodItem(from: $0) }
            isAnalyzing = false
            showingReview = true
        } catch {
            errorMessage = error.localizedDescription
            isAnalyzing = false
        }
    }

    func analyzePhoto(_ image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = "Separating Ingredients..."

        do {
            let result = try await service.analyzePhotoStructured(image)
            reviewMealName = result.mealName
            reviewItems = result.ingredients.map { ReviewableFoodItem(from: $0) }
            isAnalyzing = false
            showingReview = true
        } catch {
            errorMessage = error.localizedDescription
            isAnalyzing = false
        }
    }

    func analyzeLabel(_ image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = "Reading Nutrition Label..."

        do {
            let result = try await service.analyzeNutritionLabel(image)
            reviewMealName = result.name
            reviewItems = [ReviewableFoodItem(from: result)]
            isAnalyzing = false
            showingReview = true
        } catch {
            errorMessage = error.localizedDescription
            isAnalyzing = false
        }
    }
}
