//
//  SettingsModel.swift
//  smartMenu
//
//  Created by Ricardo Martinez on 10/12/25.
//

import SwiftData
import Foundation

@Model
class User: Identifiable {
    var id = UUID()
    var name: String
    var diet: String
    var allergies: [String]
    
    init(name: String, diet: String = "None", allergies: [String] = []) {
        self.name = name
        self.diet = diet
        self.allergies = allergies
    }
}
