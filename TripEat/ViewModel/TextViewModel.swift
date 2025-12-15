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
    
    // Internal Logic
    private var userSettings: SettingsModel?
    private var modelContext: ModelContext?
    private var session = LanguageModelSession(model: SystemLanguageModel.default)
    
    init() {
        print("TextViewModel Initialized")
    }
    
    // MARK: - Context Injection
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
        } catch {
            print("Failed to fetch settings: \(error)")
        }
    }
    
    // MARK: - Main Pipeline
    func translateAndProcess(using session: TranslationSession) async {
        guard !scannedItem.isEmpty else { return }
        
        // Start Loading Animation
        await MainActor.run { self.isProccessing = true }
        
        Task { @MainActor in
            let requests = scannedItem.map { TranslationSession.Request(sourceText: $0) }
            
            do {
                // 1. Translate
                let responses = try await session.translations(from: requests)
                scannedItem = responses.map { $0.targetText }
                
                // 2. Extract Facts (Name, Ingredients, Price)
                await extractFacts(scannedItem)
                
                // 3. Evaluate Diet (Can Eat?)
                await evaluateDiet()
                
            } catch {
                print("Pipeline Error: \(error)")
            }
            
            self.isProccessing = false
        }
    }
    
    // MARK: - Step 1: Extraction (Facts Only)
    private func extractFacts(_ textItems: [String]) async {
        let contentText = textItems.joined(separator: "\n")
        
        let prompt = """
        Analyze the menu text below.
        Extract the following for each meal:
        1. Name
        2. Ingredients (list)
        3. Price (number only, ignore currency symbols)
        4. Set 'canEat' to TRUE (default).
        
        Menu Text:
        \(contentText)
        """
        
        do {
            let response = try await session.respond(to: prompt, generating: MenuAnalysis.self)
            self.structuredMeals = response.content.meals
        } catch {
            print("Extraction Error: \(error)")
        }
    }
    
    // MARK: - Step 2: Evaluation (Logic)
    private func evaluateDiet() async {
        guard let settings = userSettings, !structuredMeals.isEmpty else { return }
        
        // Feed facts back to AI
        var menuData = ""
        for meal in structuredMeals {
            menuData += "- \(meal.name) (Ing: \(meal.ingredients.joined(separator: ", ")))\n"
        }
        
        let prompt = """
        You are a dietary assistant.
        User Rules:
        - Diet: \(settings.diet)
        - Allergies: \(settings.allergies.joined(separator: ", "))
        
        Task:
        Review the meals.
        1. If a meal contains an Allergy OR violates the Diet, set 'canEat' to FALSE.
        2. Otherwise, set 'canEat' to TRUE.
        3. Do not change Name, Ingredients, or Price.
        
        Meals:
        \(menuData)
        """
        
        do {
            let response = try await session.respond(to: prompt, generating: MenuAnalysis.self)
            self.structuredMeals = response.content.meals
            //print("")
            // Sort: Safe items first
            self.structuredMeals.sort { $0.canEat && !$1.canEat }
            
        } catch {
            print("Evaluation Error: \(error)")
        }
    }
}
