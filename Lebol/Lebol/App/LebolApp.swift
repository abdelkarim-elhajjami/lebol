import SwiftUI
import SwiftData

@main
struct LebolApp: App {
    let modelContainer: ModelContainer
    @State private var showDataResetAlert = false

    init() {
        let schema = Schema(LebolSchemaV2.models)

        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: LebolMigrationPlan.self
            )
        } catch {
            // Corrupted store — delete all SwiftData files and retry
            print("SwiftData store corrupted, resetting: \(error)")
            Self.deleteSwiftDataStore()

            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: LebolMigrationPlan.self
                )
                // Flag to show alert after UI is ready
                _showDataResetAlert = State(initialValue: true)
            } catch {
                fatalError("Could not initialize ModelContainer after reset: \(error)")
            }
        }
    }

    private static func deleteSwiftDataStore() {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }

        // Delete all .store files (default.store, .store-wal, .store-shm)
        if let files = try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.contains(".store") {
                try? fm.removeItem(at: file)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Intentional: design system has no dark mode colors yet
                .preferredColorScheme(.light)
                .alert("Data Reset", isPresented: $showDataResetAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your data was reset due to a storage issue. We're sorry for the inconvenience.")
                }
        }
        .modelContainer(modelContainer)
    }
}
