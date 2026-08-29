import SwiftUI
import SwiftData

struct FavoritesManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var favorites: [FavoriteMeal] = []
    @State private var editingFavorite: FavoriteMeal?

    var body: some View {
        Group {
            if favorites.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "star")
                        .font(.system(size: 32))
                        .foregroundColor(.lebolTextTertiary)
                    Text("No favorites yet")
                        .font(LebolFont.headline())
                        .foregroundColor(.lebolTextPrimary)
                    Text("Mark meals as favorite when\nlogging to see them here.")
                        .font(LebolFont.subheadline())
                        .foregroundColor(.lebolTextSecondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                List {
                    ForEach(favorites, id: \.id) { favorite in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(favorite.name.isEmpty ? "Favorite Meal" : favorite.name)
                                    .font(LebolFont.body())
                                    .foregroundColor(.lebolTextPrimary)
                                Text("\(Int(favorite.totalCalories)) cal · \(favorite.foodCount) item\(favorite.foodCount == 1 ? "" : "s")")
                                    .font(LebolFont.caption())
                                    .foregroundColor(.lebolTextSecondary)
                            }

                            Spacer()

                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingFavorite = favorite
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteFavorite(favorite)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Manage Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadFavorites() }
        .fullScreenCover(item: $editingFavorite) { favorite in
            MealReviewView(favorite: favorite)
        }
        .onChange(of: editingFavorite) { _, newValue in
            if newValue == nil {
                loadFavorites()
            }
        }
    }

    private func loadFavorites() {
        let descriptor = FetchDescriptor<FavoriteMeal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        favorites = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func deleteFavorite(_ favorite: FavoriteMeal) {
        Haptics.error()
        DataService.deleteFavorite(favorite, in: modelContext)
        loadFavorites()
    }
}
