import SwiftUI
import VisionKit

struct DataScanner: UIViewControllerRepresentable {
    
    @Binding var recognizedItems: [String]
    @Binding var startScanning: Bool
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true, // scans everything
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        
        // Start the background task to watch the video stream
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
                
                // 1. Update the bindings with the text found
                context.coordinator.parent.recognizedItems = items.compactMap { item in
                    switch item {
                    case .text(let text): return text.transcript
                    default: return nil
                    }
                }
                
                // 2. Turn the trigger off (this signals the UI that we are done)
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
