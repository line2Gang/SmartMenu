//
//  TripEatApp.swift
//  TripEat
//
//  Created by Christian Ostoni on 15/12/25.
//

import SwiftUI
import SwiftData
@main
struct TripEatApp: App {
    var body: some Scene {
        WindowGroup {
            settingsView()
        }.modelContainer(for: SettingsModel.self)
    }
}
