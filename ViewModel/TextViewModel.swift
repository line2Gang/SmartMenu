import Foundation
import Translation
import Combine
import FoundationModels
import SwiftData

@Observable
class TextViewModel {
    var scannedItem: [String] = []
    var structuredMeals: [Meal] = []
    var isProccessing: Bool = false
    
    private var userSettings: SettingsModel?
    private var modelContext: ModelContext?
    
    private var session = LanguageModelSession(model:SystemLanguageModel.default)
    
    init() {
        // This will now only print ONCE
        switch SystemLanguageModel.default.availability {
        case .available:
            print("AI Model: Available")
        case .unavailable(let reason):
            print("AI Model Unavailable: \(reason)")
        @unknown default:
            print("AI Model Status Unknown")
        }
    }
    func setContext(_ context: ModelContext) {
        self.modelContext = context
        fetchSettings()
    }
    
    private func fetchSettings() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<SettingsModel>()
        do {
            let results = try context.fetch(descriptor)
            self.userSettings = results.first
            print("Settings loaded: Diet is \(userSettings?.diet ?? "None")")
        } catch {
            print("Failed to fetch settings: \(error)")
        }
    }
    
    func translateAllAtOnce(using session: TranslationSession) async {
        Task { @MainActor in
            // 1. Translation
            let requests: [TranslationSession.Request] = scannedItem.map {
                TranslationSession.Request(sourceText: $0)
            }
            
            do {
                let responses = try await session.translations(from: requests)
                scannedItem = responses.map { $0.targetText }
                
                // 2. Structure (Extract Meals)
                await extractStructure(scannedItem)
                await sortMenu()
                
            } catch {
                print("Translation Error: \(error)")
            }
        }
    }
    
    private func extractStructure(_ textItems: [String]) async {
        let contentText = textItems.joined(separator: "\n")
        let prompt = """
        Analyze the following menu. Group the lines into distinct meals.
        For each meal extract or generate the ingredients and the name.
        Keep in mind that not all the information on the menu are meals, 
        but can me information about the "portata"
        Menu Text:
        \(contentText)
        """
        
        do {
            let response = try await session.respond(to: prompt, generating: MenuAnalysis.self)
            self.structuredMeals = response.content.meals // or .object.meals depending on SDK
            print("menu before sorting: \(structuredMeals)")
        } catch {
            print("AI Extraction Error: \(error)")
        }
    }
    
    @MainActor
    private func sortMenu() async {
        // Guard: Check if we have meals AND settings. If not, stop.
        guard !structuredMeals.isEmpty, let settings = userSettings else {
            print("Skipping sort: Missing meals or user settings.")
            return
        }
        
        self.isProccessing = true
        
        // 1. Prepare Data
        var menuDescription = ""
        for meal in structuredMeals {
            menuDescription += "- \(meal.name): \(meal.ingredients.joined(separator: ", "))\n"
        }
        
        // 2. Create Prompt using internal settings
        let prompt = """
            You are a dietary assistant.
            
            User Profile:
            - Diet: \(settings.diet)
            - Allergies: \(settings.allergies.joined(separator: ", "))
            
            Task:
            Re-order this list. Put safe meals (fitting diet, no allergies) at the top.
            
            Menu:
            \(menuDescription)
            """
        
        // 3. AI Request
        do {
            let response = try await session.respond(to: prompt, generating: MenuAnalysis.self)
            
            // 4. Update Data (View will automatically update because of @Observable)
            //self.structuredMeals = response.content.meals
            print("sorted menu: \(response.content.meals)")
            
            
            
            print("Menu Sorted successfully based on \(settings.diet) and \(settings.aller)")
            
        } catch {
            print("AI Sorting Error: \(error)")
        }
        
        self.isProccessing = false
    }
}
