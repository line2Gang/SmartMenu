//
//  ProfilViewModel.swift
//  smartMenu
//
//  Created by Viranaiken Jessy on 14/12/25.
//
import Foundation
import SwiftData

@Observable
final class UserController {
    // MARK: - Property
    var context: ModelContext? = nil
    var users: [User] = []
    var currentUser: User? = nil
    // MARK: - Create
    func createUser(name: String, diet: String?, allergies: [String]?) {
        /// Verify the context otherwise return nil directly
        guard let context = self.context else { return }
        let newUser = User(name: name)
        if let diet = diet {
            newUser.diet = diet
        }
        if let allergies = allergies {
            newUser.allergies = allergies
        }
        do {
            /// Insert the new user
            context.insert(newUser)
            /// Save the new user
            try context.save()
            /// Refresh
            self.getUsers()
            /// Print
            print("User added: \(newUser)")
        } catch {
            print("Error during adding new user: \(error.localizedDescription)")
        }
    }
    // MARK: - Read
    func getUsers() {
        let descriptor = FetchDescriptor<User>()
        do {
            if let results = try self.context?.fetch(descriptor) {
                self.users = results
            }
            print("Users loaded: Diet is \(self.users.first?.diet ?? "None")")
        } catch {
            print("Failed to users: \(error)")
        }
    }
    // MARK: - Select user
    func selectUser(user: User) {
        self.currentUser = user
        print(user.name)
    }
}
