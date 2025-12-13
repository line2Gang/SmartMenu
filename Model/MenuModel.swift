// File: MenuModels.swift
import Foundation
import FoundationModels

@Generable
struct MenuAnalysis {
    @Guide(description: "A list of all distinct meals found in the text.")
    let meals: [Meal]
}

@Generable
struct Meal: Identifiable, Hashable {
    @Guide(description: "The name of the dish.")
    let name: String
    
    @Guide(description: "A list of ingredients or description details for this meal.")
    let ingredients: [String]
    
    var id: String { name }
}
