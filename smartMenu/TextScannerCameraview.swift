import SwiftUI
import VisionKit
import Translation

struct TextScannerCameraview: View {
    // All scanned items (State acts as our data source here)
    @State private var scannedItems: [String] = []
    
    // Translation Configuration State
    @State private var configuration: TranslationSession.Configuration?
    
    // Hardcoded languages as requested
    private var sourceLanguage = Locale.Language(identifier: "en")
    private var targetLanguage = Locale.Language(identifier: "it")
    
    // Camera states
    @State private var showCamera: Bool = false
    @State private var performCapture: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                if scannedItems.isEmpty {
                    ContentUnavailableView(
                        "No Menu Scanned",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Scan a menu to translate it")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            
                            HStack {
                                Text("Scanned Menu Items")
                                    .font(.headline)
                                Spacer()
                                Text("\(scannedItems.count) items found")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            
                            ForEach(scannedItems, id: \.self) { item in
                                VStack(alignment: .leading) {
                                    Text(item)
                                        .font(.body)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    
                    // 1. TRANSLATE BUTTON (Only show if we have items)
                    if !scannedItems.isEmpty {
                        Button(action: {
                            triggerTranslation()
                        }) {
                            Label("Translate to Italian", systemImage: "translate")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    // 2. SCAN BUTTON
                    Button(action: {
                        showCamera = true
                    }) {
                        Label(scannedItems.isEmpty ? "Scan Menu" : "Scan Again", systemImage: "camera.fill")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Smart Menu")
            
            // --- TRANSLATION LOGIC STARTS HERE ---
            .translationTask(configuration) { session in
                do {
                    // 1. Prepare the batch of requests from your scanned array
                    let requests: [TranslationSession.Request] = scannedItems.map { item in
                        TranslationSession.Request(sourceText: item)
                    }
                    
                    // 2. Send the batch to Apple's engine
                    let responses = try await session.translations(from: requests)
                    
                    // 3. Update the UI with results
                    // We replace the English text with the Italian text directly
                    scannedItems = responses.map { $0.targetText }
                    
                } catch {
                    print("Translation error: \(error)")
                }
            }
            // --- TRANSLATION LOGIC ENDS HERE ---
            
            .fullScreenCover(isPresented: $showCamera) {
                ZStack(alignment: .bottom) {
                    DataScanner(
                        recognizedItems: $scannedItems,
                        startScanning: $performCapture
                    )
                    .ignoresSafeArea()
                    
                    Button(action: {
                        performCapture = true
                    }) {
                        Text("Capture Text")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .padding(.horizontal, 20)
                            .background(Color.blue)
                            .cornerRadius(30)
                            .padding(.bottom, 50)
                            .shadow(radius: 10)
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showCamera = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                                    .padding()
                                    .padding(.top, 40)
                            }
                        }
                        Spacer()
                    }
                }
                .onChange(of: performCapture) { oldValue, newValue in
                    if newValue == false {
                        showCamera = false
                    }
                }
            }
        }
    }
    
    // Helper function to trigger the configuration update
    private func triggerTranslation() {
        if configuration == nil {
            configuration = .init(source: sourceLanguage, target: targetLanguage)
        } else {
            configuration?.invalidate()
        }
    }
}

#Preview {
    TextScannerCameraview()
}
