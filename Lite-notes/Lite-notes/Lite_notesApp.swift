import SwiftUI
import SwiftData

@main
struct Lite_notesApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Note.self, Template.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}