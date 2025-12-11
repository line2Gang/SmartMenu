import Foundation
import Translation
internal import Combine
import FoundationModels

class TextViewModel:ObservableObject{
    @Published var scannedItem: [String] = []
    @Published var structuredMeals:[Meal] = []
    
    
    
    private let model = SystemLanguageModel.default
    private lazy var session = LanguageModelSession(model:model)
    
    init(){
        switch model.availability{
        case .available:
            print("disponibile")
        case .unavailable(.deviceNotEligible):
            print("device not eligible")
            return;
        case .unavailable(.appleIntelligenceNotEnabled):
            print("apple intellignece not enabled")
            return;
        case .unavailable(.modelNotReady):
            print("model not ready")
            return;
        case .unavailable(let other):
            print("indisponibile altro")
            return;
        }
    }

    
    func translateAllAtOnce(using session: TranslationSession) async {
        Task{@MainActor in
            let requests:[TranslationSession.Request] = scannedItem.map{
                TranslationSession.Request(sourceText: $0)
            }
            do{
                let responses = try await session.translations(from: requests)
                scannedItem = responses.map{$0.targetText}
                await extractStructure(scannedItem)
                
                print("Translation complete: \(structuredMeals)")
            }catch{
                //To do: which type of error I can have??
            }
            
        }
    }
    
    private func extractStructure(_ textItems:[String]) async {
        let contentText = textItems.joined(separator: "\n")
        let prompt = """
                     analyze the following menu. Group the lines into dinstinct meals. 
                     for each meal extract or generate the ingredients and the name.  
                     menu text:
                     \(contentText)
                     """
        do{
            let response = try await session.respond(to: prompt, generating: MenuAnalysis.self)
            self.structuredMeals = response.content.meals
        }
        catch{
            print("I got some errors with AI: \(error)")
        }
    }
}
