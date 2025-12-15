import SwiftUI
import VisionKit

struct DataScanner: UIViewControllerRepresentable {
    
    @Binding var recognizedItems: [String]
    @Binding var startScanning: Bool
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        
        Task {
            for await items in scanner.recognizedItems {
                context.coordinator.currentItems = items
            }
        }
        
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Trigger: When the user presses "Capture"
        if startScanning {
            Task { @MainActor in
                let items = context.coordinator.currentItems
                
                context.coordinator.parent.recognizedItems = items.compactMap { item in
                    switch item {
                    case .text(let text): return text.transcript
                    default: return nil
                    }
                }
                
                context.coordinator.parent.startScanning = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: DataScanner
        var currentItems: [RecognizedItem] = [] // Buffer
        
        init(_ parent: DataScanner) {
            self.parent = parent
        }
    }
}
