import SwiftUI
import SwiftData

@main
struct smartMenuApp: App {
    var body: some Scene {
        WindowGroup {
            settingsView()
        }
        .modelContainer(for: SettingsModel.self)
    }
}
