//
//  AnalyserController.swift
//  smartMenu
//
//  Created by Viranaiken Jessy on 14/12/25.
//
import FoundationModels
import Foundation
import Translation

@Observable
final class AnalyserController {
    // MARK: - Property
    // Configuration
    let session = LanguageModelSession(instructions:
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
    )
    @ObservationIgnored
    private let model = SystemLanguageModel.default
    // Will save extractedText
    var extractedText: [Meal] = []
    // Will save the sortedMenu
    var sortedMenu: [Meal] = []
    // MARK: - Init
    init() {
        /// Verify the availability
        switch self.model.availability {
        case .available:
            print("Apple Intelligence available !")
        case .unavailable(.appleIntelligenceNotEnabled):
            print("Apple Intelligence not enabled, please go to your settings top turn on.")
        case .unavailable(.deviceNotEligible):
            print("Apple Intelligence not available on this model of device.")
        case .unavailable(.modelNotReady):
            print("Apple Intelligence model not ready. Please try again")
        @unknown default:
            print("Unknown error")
        }
    }
    // MARK: - Extract
    func extractMenu(from text: [String]) async {
        /// Parse the input
        let convertedText = text.joined(separator: "\n")
        let prompt =
"""
                        Analyze carefully the following menu text and extract the list of meals.
                        For each meal:
                        1. Extract the Name.
                        2. Extract the list of Ingredients.
                        3. Extract the Price (as a number).
                        4. Set 'canEat' to TRUE for all items (we will check allergies later).
                        
                        Menu Text:
                        \(convertedText)
"""
        do {
            /// Request
            let response = try await self.session.respond(to: prompt, generating: MenuModel.self)
            /// Save the response
            self.extractedText = response.content.meals
        } catch {
            print("Error during extraction: \(error.localizedDescription)")
        }
    }
    // MARK: - Sort
    func sortMenu(regarding user: User?) async {
        /// Verify before run the function
        guard !self.extractedText.isEmpty, let user = user else {
            print("Input empty of error user (1)")
            return
        }
        /// Parse menu
        var convertedMenu = ""
        for item in self.extractedText {
            convertedMenu += "- \(item.name): \(item.ingredients.joined(separator: ", "))\n"
        }
        let prompt =
            """
            You are a dietary assistant.
            
            User Profile:
            - Diet: \(user.diet)
            - Allergies: \(user.allergies.joined(separator: ", "))
            
            Task:
            Re-order this list. Put safe meals (fitting diet, no allergies) at the top.
            
            Menu:
            \(convertedMenu)
            """
        do {
            /// Request the model
            let response = try await self.session.respond(to: prompt, generating: MenuModel.self)
            /// Save the response
            self.sortedMenu = response.content.meals
            /// Print
            print("sorted menu: \(response.content.meals)")
            print("Menu Sorted successfully based on \(user.diet) and \(user.allergies)")
        } catch {
            print("Error during sorting process: \(error.localizedDescription)")
        }
    }
}
