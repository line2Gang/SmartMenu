import SwiftUI
import SwiftData

@main
struct smartMenuApp: App {
    
    @Environment(\.modelContext)
    var context
    @State
    private var translationController = TranslationController()
    @State
    private var analyserController = AnalyserController()
    @State
    private var userController = UserController()
    
    var body: some Scene {
        WindowGroup {
            TextScannerCameraView()
                .environment(translationController)
                .environment(analyserController)
                .environment(userController)
        }
        .modelContainer(for: User.self)
    }
}
