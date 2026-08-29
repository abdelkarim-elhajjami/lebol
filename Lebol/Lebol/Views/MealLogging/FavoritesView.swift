import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var favorites: [FavoriteMeal] = []

    let onMealSelected: ([ReviewableFoodItem], String) -> Void

    var body: some View {
        NavigationStack {

            if favorites.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "star")
                        .font(.system(size: 32))
                        .foregroundColor(.lebolTextTertiary)
                    Text("No favorites yet")
                        .font(LebolFont.headline())
                        .foregroundColor(.lebolTextPrimary)
                    Text("Mark meals as favorite from\nmeal details to see them here.")
                        .font(LebolFont.subheadline())
                        .foregroundColor(.lebolTextSecondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(favorites, id: \.id) { favorite in
                            favoriteMealRow(favorite: favorite)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .onAppear { favorites = fetchFavorites() }
        .background(Color.lebolBackground)
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .lebolDismissToolbar()
    }

    private func favoriteMealRow(favorite: FavoriteMeal) -> some View {
        Button {
            Haptics.light()
            let items = favorite.toReviewableItems()
            onMealSelected(items, favorite.name)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(favorite.name.isEmpty ? "Favorite Meal" : favorite.name)
                        .font(LebolFont.body())
                        .foregroundColor(.lebolTextPrimary)
                        .lineLimit(1)
                    Text("\(Int(favorite.totalCalories)) cal · \(favorite.foodCount) item\(favorite.foodCount == 1 ? "" : "s")")
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolTextSecondary)
                }

                Spacer()

                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func fetchFavorites() -> [FavoriteMeal] {
        let descriptor = FetchDescriptor<FavoriteMeal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
