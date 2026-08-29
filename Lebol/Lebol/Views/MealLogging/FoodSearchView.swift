import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.foodAnalysisService) private var foodAnalysisService

    let onFoodSelected: (ReviewableFoodItem) -> Void

    @State private var searchText = ""
    @State private var searchResults: [StructuredFoodResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var recentFoods: [FoodItem] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.lebolTextSecondary)
                    TextField("Search by ingredients", text: $searchText)
                        .font(LebolFont.body())
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.lebolTextSecondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.lebolSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if isSearching {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    Text(error)
                        .font(LebolFont.subheadline())
                        .foregroundColor(.lebolTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else if searchText.isEmpty {
                    suggestionsSection
                } else if searchResults.isEmpty {
                    Spacer()
                    Text("No results found")
                        .font(LebolFont.subheadline())
                        .foregroundColor(.lebolTextSecondary)
                    Spacer()
                } else {
                    resultsList
                }
            }
            .background(Color.lebolBackground)
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .lebolDismissToolbar()
        }
        .onAppear {
            recentFoods = fetchRecentFoods()
        }
        .onChange(of: searchText) { _, newValue in
            debounceSearch(query: newValue)
        }
    }

    // MARK: - Suggestions (recently logged foods)

    private var suggestionsSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !recentFoods.isEmpty {
                    Text("Suggestions")
                        .font(LebolFont.headline())
                        .foregroundColor(.lebolTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    ForEach(recentFoods, id: \.id) { food in
                        suggestionRow(food: food)
                    }
                } else {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 60)
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.lebolTextTertiary)
                        Text("Search for foods like\n\"chicken breast\" or \"oatmeal\"")
                            .font(LebolFont.subheadline())
                            .foregroundColor(.lebolTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func suggestionRow(food: FoodItem) -> some View {
        Button {
            Haptics.light()
            let item = ReviewableFoodItem(from: food)
            onFoodSelected(item)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(LebolFont.body())
                        .foregroundColor(.lebolTextPrimary)
                    Text("\(Int(food.calories)) cal · \(Int(food.displayQuantity)) \(food.displayUnitLabel)")
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolTextSecondary)
                }

                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.lebolTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.lebolDivider)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Search Results

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults) { result in
                    searchResultRow(result)
                }
            }
            .padding(.top, 8)
        }
    }

    private func searchResultRow(_ result: StructuredFoodResult) -> some View {
        Button {
            Haptics.light()
            let item = ReviewableFoodItem(from: result)
            onFoodSelected(item)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(LebolFont.body())
                        .foregroundColor(.lebolTextPrimary)
                    Text("\(Int(result.calories)) cal · \(result.portionDescription)")
                        .font(LebolFont.caption())
                        .foregroundColor(.lebolTextSecondary)
                }

                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.lebolTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.lebolDivider)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Search Logic

    private func debounceSearch(query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            errorMessage = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }

            isSearching = true; errorMessage = nil

            do {
                let results = try await foodAnalysisService.lookupFood(query)
                guard !Task.isCancelled else { return }
                searchResults = results
                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                isSearching = false
            }
        }
    }

    // MARK: - Recent Foods

    private func fetchRecentFoods() -> [FoodItem] {
        var descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.fetchLimit = 20

        guard let foods = try? modelContext.fetch(descriptor) else { return [] }

        // Deduplicate by name
        var seen = Set<String>()
        return foods.filter { food in
            let key = food.name.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
}
