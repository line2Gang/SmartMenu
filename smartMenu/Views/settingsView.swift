//
//  settingsView.swift
//  smartMenu
//
//  Created by Ricardo Martinez on 10/12/25.
//

import SwiftUI
import SwiftData

struct settingsView: View {
    
    @Environment(\.modelContext) private var context
    @Query var settings: [SettingsModel]

    
    @State private var showSavedToast = false
    @State private var navigateToNext = false
    @State private var selectedLanguage: String =
        Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "")
        ?? "None"
    @State private var selectedDiet: String = "None"
    @State private var allergyInput: String = ""
    @State private var allergies: [String] = []
    
    // MARK: - Searcher
        @State private var showLanguageSelector = false
        @State private var searchText = ""

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
        NavigationView {
            Form {

                // MARK: - LANGUAGE PICKER WITH SEARCH
                Section(header: Text("Language")) {
                    Button(action: { showLanguageSelector = true }) {
                        HStack {
                            
                            Text(selectedLanguage == "None" ? "None" : selectedLanguage)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
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
                                    selectedLanguage = lang
                                    showLanguageSelector = false
                                }) {
                                    HStack {
                                        Text(lang)
                                        Spacer()
                                        if lang == selectedLanguage {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .navigationTitle("Select Language")
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
                        
                        // Espera 2 segundos, luego navega
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            navigateToNext = true
                        }
                        
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
                            // Ocultar después de 2 segundos por si se usa en otro contexto
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
            existing.language = selectedLanguage
            existing.diet = selectedDiet
            existing.allergies = allergies
        } else {
            let newSettings = SettingsModel(language: selectedLanguage,
                                            diet: selectedDiet,
                                            allergies: allergies)
            context.insert(newSettings)
        }

        try? context.save()
    }

    private func loadExistingSettings() {
        if let existing = settings.first {
            selectedLanguage = existing.language
            selectedDiet = existing.diet
            allergies = existing.allergies
        }
    }
    
}




#Preview {
    settingsView()
}
