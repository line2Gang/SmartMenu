    //
    //  SettingsModel.swift
    //  smartMenu
    //
    //  Created by Ricardo Martinez on 10/12/25.
    //

    import SwiftData
    import Foundation

    @Model
    class SettingsModel {
        var sourceLanguage: String
        var targetLanguage: String
        var diet: String
        var allergies: [String]

        init(sourceLanguage: String = Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "") ?? "English",
             targetLanguage: String = "Italian", // Default example
             diet: String = "None",
             allergies: [String] = []) {
            
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
            self.diet = diet
            self.allergies = allergies
        }
    }
