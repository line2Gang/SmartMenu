//
//  settingsView.swift
//  smartMenu
//
//  Created by Ricardo Martinez on 10/12/25.
//

import SwiftUI
import SwiftData
import Translation // Imported if you need Locale helpers, otherwise Foundation is enough

struct settingsView: View {
    
    @Environment(\.modelContext) private var context
    @Query var settings: [SettingsModel]

    @State private var showSavedToast = false
    @State private var navigateToNext = false
    
    // Default values
    @State private var selectedTargetLanguage: String = "Italian"
    @State private var selectedSourceLanguage: String =
        Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "") ?? "English"
    
    @State private var selectedDiet: String = "None"
    @State private var allergyInput: String = ""
    @State private var allergies: [String] = []
    
    // MARK: - Searcher & Selection Logic
    @State private var showLanguageSelector = false
    @State private var searchText = ""
    
    // Enum to know which button triggered the sheet
    enum LanguageField {
        case source
        case target
    }
    @State private var activeField: LanguageField = .target

    // MARK: - Dynamic system language list
    private var systemLanguages: [String] {
        let identifiers = Locale.availableIdentifiers
        let languageCodes = identifiers.compactMap { Locale(identifier: $0).languageCode }
        let localizedNames = languageCodes.compactMap { Locale.current.localizedString(forLanguageCode: $0) }
        return Array(Set(localizedNames)).sorted()
    }
    
    // MARK: - Filter Language list
    private var filteredLanguages: [String] {
        if searchText.isEmpty { return systemLanguages }
        return systemLanguages.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    let diets = [
        "None", "Vegetarian", "Vegan", "Pescatarian",
        "Keto", "Paleo", "Gluten-Free", "Dairy-Free"
    ]
    

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - LANGUAGE PICKER WITH SEARCH
                Section(header: Text("Language")) {
                    
                    // Button for Target Language
                    Button(action: {
                        activeField = .target
                        searchText = "" // Clear search
                        showLanguageSelector = true
                    }) {
                        HStack {
                            Text("Target Language:")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(selectedTargetLanguage)
                                .foregroundColor(.gray)
                        }
                    }

                    // Button for Source Language
                    Button(action: {
                        activeField = .source
                        searchText = "" // Clear search
                        showLanguageSelector = true
                    }) {
                        HStack {
                            Text("Source Language:")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(selectedSourceLanguage)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // MARK: - SHARED LANGUAGE SHEET
                .sheet(isPresented: $showLanguageSelector) {
                    NavigationView {
                        VStack {
                            // Search field
                            TextField("Search language...", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()

                            // Filtered results
                            List(filteredLanguages, id: \.self) { lang in
                                Button(action: {
                                    // Update the variable based on which button was clicked
                                    if activeField == .target {
                                        selectedTargetLanguage = lang
                                    } else {
                                        selectedSourceLanguage = lang
                                    }
                                    showLanguageSelector = false
                                }) {
                                    HStack {
                                        Text(lang)
                                        Spacer()
                                        
                                        // Show checkmark if this language is the currently selected one for the active field
                                        if (activeField == .target && lang == selectedTargetLanguage) ||
                                           (activeField == .source && lang == selectedSourceLanguage) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .navigationTitle(activeField == .target ? "Select Target" : "Select Source")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showLanguageSelector = false }
                            }
                        }
                    }
                }
                
                // MARK: DIET PICKER
                Section(header: Text("Specific Diet")) {
                    Picker("Diet", selection: $selectedDiet) {
                        ForEach(diets, id: \.self) { diet in
                            Text(diet)
                        }
                    }
                }

                // MARK: ALLERGIES INPUT
                Section(header: Text("Allergies")) {
                    HStack {
                        TextField("Add allergy", text: $allergyInput)

                        Button(action: addAllergy) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(allergyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    ForEach(allergies, id: \.self) { allergy in
                        Text("• \(allergy)")
                    }
                    .onDelete(perform: deleteAllergy)
                }

                // MARK: ACCEPT BUTTON
                Section {
                    Button(action: {
                        saveSettings()
                        showSavedToast = true
                        
                        // Navigate after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            navigateToNext = true
                        }
                    }) {
                        Text("Save") // Changed text to indicate flow
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            
            .navigationTitle("Settings")
            //.navigationBarTitleDisplayMode(.inline)
            .onAppear { loadExistingSettings() }
            .navigationDestination(isPresented: $navigateToNext) {
                TextScannerCameraview()
            }
        }
        .overlay(
            Group {
                if showSavedToast {
                    Text("Settings Saved")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showSavedToast = false
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut, value: showSavedToast)
        )
    }
        

    // MARK: - FUNCTIONS
    private func addAllergy() {
        let trimmed = allergyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        allergies.append(trimmed)
        allergyInput = ""
    }

    private func deleteAllergy(at offsets: IndexSet) {
        allergies.remove(atOffsets: offsets)
    }

    private func saveSettings() {
        if let existing = settings.first {
            existing.sourceLanguage = selectedSourceLanguage
            existing.targetLanguage = selectedTargetLanguage
            existing.diet = selectedDiet
            existing.allergies = allergies
        } else {
            let newSettings = SettingsModel(
                sourceLanguage: selectedSourceLanguage,
                targetLanguage: selectedTargetLanguage,
                diet: selectedDiet,
                allergies: allergies
            )
            context.insert(newSettings)
        }

        try? context.save()
    }

    private func loadExistingSettings() {
        if let existing = settings.first {
            selectedSourceLanguage = existing.sourceLanguage
            selectedTargetLanguage = existing.targetLanguage
            selectedDiet = existing.diet
            allergies = existing.allergies
        }
    }
    
}

#Preview {
    settingsView()
}
