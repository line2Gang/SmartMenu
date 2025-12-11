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
    var language: String
    var diet: String
    var allergies: [String]

    init(language: String = Locale.current.identifier,
         diet: String = "None",
         allergies: [String] = []) {
        self.language = language
        self.diet = diet
        self.allergies = allergies
    }
}
