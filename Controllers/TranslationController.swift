//
//  TranslationController.swift
//  smartMenu
//
//  Created by Viranaiken Jessy on 14/12/25.
//
import Translation
import NaturalLanguage

@Observable
final class TranslationController {
    // MARK: - Property
    let session: TranslationSession
    let sourceLanguage = Locale.Language(identifier: "it")
    let targetLanguage: Locale.Language
    // Will save translated text
    var translatedText: [String] = []
    // MARK: - Init
    init(target: Locale.Language = Locale.Language(identifier: "en")) {
        self.targetLanguage = target
        self.session = TranslationSession(installedSource: self.sourceLanguage, target: targetLanguage)
    }
    // MARK: - Translate
    func translate(sourceText: [String]) async {
        let requests: [TranslationSession.Request] = sourceText.map {
            TranslationSession.Request(sourceText: $0)
        }
        do {
            let responses = try await session.translations(from: requests)
            self.translatedText = responses.map { $0.targetText }
            // Print
            print(self.translatedText)
        } catch {
            print("Error during the translation: \(error.localizedDescription)")
        }
    }
}

