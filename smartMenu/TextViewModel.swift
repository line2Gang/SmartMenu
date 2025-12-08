import Foundation
import Translation
internal import Combine

class TextViewModel:ObservableObject{
    @Published var scannedItem: [String] = []     
    func translateAllAtOnce(using session: TranslationSession) async {
        Task{@MainActor in
            let requests:[TranslationSession.Request] = scannedItem.map{
                TranslationSession.Request(sourceText: $0)
            }
            do{
                let responses = try await session.translations(from: requests)
                scannedItem = responses.map{$0.targetText}
            }catch{
                //To do: which type of error I can have??
            }
            
        }
    }
}
