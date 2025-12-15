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
    
    private var user: User?
    
    private var session = LanguageModelSession(model:SystemLanguageModel.default)
    
    let instructions: String =
"""
                    You are a menu analysis assistant. Your job is to extract distinct meals from a restaurant menu text.
                    
                    RULES:
                    1. Identify distinct dishes/meals (e.g., "Carbonara Pasta", "Grilled Salmon", "Tiramisu").
                    2. IGNORE menu section headers, course names, or categories. Examples of text to IGNORE:
                       - "Primi Piatti", "Secondi", "Contorni", "Dessert", "Bevande"
                       - "Starters", "Main Courses", "Sides", "Drinks"
                       - "Antipasti", "Insalate", "Pizze"
                    3. Get prices (e.g., "€10", "$15.50").
                    4. For each valid meal, extract its name and its ingredients and description.
                    5. If a line is just a category name (like "Primi"), DO NOT create a Meal object for it.
                    6. Be careful to dinstinct different meals from their ingredients
"""
    
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
    
    //    func translateAllAtOnce(using session: TranslationSession) async {
    //        Task { @MainActor in
    //            // 1. Translation
    //            let requests: [TranslationSession.Request] = scannedItem.map {
    //                TranslationSession.Request(sourceText: $0)
    //            }
    //
    //            do {
    //                let responses = try await session.translations(from: requests)
    //                scannedItem = responses.map { $0.targetText }
    //
    //                // 2. Structure (Extract Meals)
    //                await extractStructure(scannedItem)
    //                await sortMenu()
    //
    //            } catch {
    //                print("Translation Error: \(error)")
    //            }
    //        }
    //    }
    
    private func extractStructure(_ textItems: [String]) async {
        let contentText = textItems.joined(separator: "\n")
        let prompt = """
        Analyze the following menu. Group the lines into distinct meals.
        For each meal extracted, generate the ingredients and the name.
        Keep in mind that not all the information on the menu are meals, 
        but give me information about the "portata"
        Menu Text:
        \(contentText)
        """
        
        do {
            let response = try await session.respond(to: prompt, generating: MenuModel.self)
            self.structuredMeals = response.content.meals // or .object.meals depending on SDK
            print("menu before sorting: \(structuredMeals)")
        } catch {
            print("AI Extraction Error: \(error)")
        }
    }
    
    @MainActor
    private func sortMenu() async {
        // Guard: Check if we have meals AND settings. If not, stop.
        guard !structuredMeals.isEmpty, self.user != nil else {
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
            - Diet: \(self.user!.diet)
            - Allergies: \(self.user!.allergies.joined(separator: ", "))
            
            Task:
            Re-order this list. Put safe meals (fitting diet, no allergies) at the top.
            
            Menu:
            \(menuDescription)
            """
        
        // 3. AI Request
        do {
            let response = try await session.respond(to: prompt, generating: MenuModel.self)
            
            // 4. Update Data (View will automatically update because of @Observable)
            //self.structuredMeals = response.content.meals
            print("sorted menu: \(response.content.meals)")
            
            
            
            print("Menu Sorted successfully based on \(self.user!.diet) and \(self.user!.allergies)")
            
        } catch {
            print("AI Sorting Error: \(error)")
        }
        
        self.isProccessing = false
    }
}
