//
//  settingsView.swift
//  smartMenu
//
//  Created by Ricardo Martinez on 10/12/25.
//

import SwiftUI
import SwiftData
import Translation

struct UserProfilView: View {
    
    @Environment(UserController.self)
    private var userController
    @Environment(\.dismiss)
    private var dismiss
    
    @Binding
    var isPresented: Bool
    
    @State
    private var selectedDiet: String = "None"
    
    private let diets = ["None", "Vegetarian", "Vegan", "Pescatarian", "Keto", "Paleo", "Gluten-Free", "Dairy-Free"]
    
    @State
    private var selectedAllergies: [String] = []
    
    private let allergies: [String] = ["Dairy", "Eggs", "Nuts", "Gluten", "Shellfish"]
    
    @State
    private var name: String = ""

    var body: some View {
        Form {
            // MARK: - LANGUAGE PICKER WITH SEARCH
            Section(header: Text("Name")) {
                TextField("Type your name", text: self.$name)
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
                VStack {
                    ForEach(self.allergies, id: \.self) { allergy in
                        Button(allergy) {
                            self.selectedAllergies.append(allergy)
                        }
                    }
                }
            }
            // MARK: ACCEPT BUTTON
            Section {
                HStack(alignment: .center) {
                    Spacer()
                    Button("Save") {
                        if !self.name.isEmpty {
                            userController.createUser(name: self.name, diet: self.selectedDiet, allergies: self.selectedAllergies)
                        }
                    }
                    Spacer()
                }
            }
            Section(header: Text("Diplay users")) {
                ForEach(userController.users, id: \.id) { user in
                    Button {
                        userController.selectUser(user: user)
                    } label: {
                        Text(user.name)
                            .foregroundStyle(.white)
                            .bold()
                    }
                    .padding()
                    .frame(width: 300, height: 75)
                    .background(userController.currentUser == user ? .blue : Color(.systemGray3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
}
