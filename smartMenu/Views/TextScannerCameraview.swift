import SwiftUI
import VisionKit
import Translation
import SwiftData
import Foundation

struct TextScannerCameraview: View {
    @ObservedObject private var textViewModel = TextViewModel()
    
    @State private var configuration: TranslationSession.Configuration?
    
    // Camera states
    @State private var showCamera: Bool = false
    @State private var performCapture: Bool = false
    
    // Add a local state to track processing if not in ViewModel
    @State private var isProcessing: Bool = false
    @Query var settings:[SettingsModel]
    
    var body: some View {
            VStack(spacing: 20) {
                
                if textViewModel.scannedItem.isEmpty {
                    ContentUnavailableView(
                        "No Menu Scanned",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Scan a menu to translate it")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            
                            HStack {
                                Text("Menu Items")
                                    .font(.headline)
                                Spacer()
                                if isProcessing {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text("\(textViewModel.scannedItem.count) items")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            // 1. Show Structured Meals (AI Result) if available
                            if !textViewModel.structuredMeals.isEmpty {
                                ForEach(textViewModel.structuredMeals, id: \.self) { meal in
                                    VStack(alignment: .leading) {
                                        Text(meal.name)
                                            .font(.headline)
                                        if !meal.ingredients.isEmpty {
                                            Text(meal.ingredients.joined(separator: ", "))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                            // 2. Show Raw text if AI hasn't finished yet
                            else {
                                ForEach(textViewModel.scannedItem, id: \.self) { item in
                                    Text(item)
                                        .font(.body)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    // "Translate" Button is REMOVED from here
                    
                    Button(action: {
                        showCamera = true
                    }) {
                        Label(textViewModel.scannedItem.isEmpty ? "Scan Menu" : "Scan Again", systemImage: "camera.fill")
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
            .navigationBarTitleDisplayMode(.inline)
            
            // 3. Translation Task runs automatically when configuration changes
            .translationTask(configuration) { session in
                isProcessing = true
                await textViewModel.translateAllAtOnce(using: session)
                isProcessing = false
            }
            
            .fullScreenCover(isPresented: $showCamera) {
                ZStack(alignment: .bottom) {
                    DataScanner(
                        recognizedItems: $textViewModel.scannedItem,
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
                // --- THE MAGIC HAPPENS HERE ---
                .onChange(of: performCapture) { oldValue, newValue in
                    if newValue == false {
                        showCamera = false
                        
                        // 4. Trigger translation automatically if we have text
                        if !textViewModel.scannedItem.isEmpty {
                            // Reset previous results to avoid confusion
                            textViewModel.structuredMeals = []
                            triggerTranslation()
                        }
                    }
                }
            }
        }
    private func triggerTranslation() {
        let userSettings = settings.first
        
        let savedSource = userSettings?.sourceLanguage ?? "English"
        let savedTarget = userSettings?.targetLanguage ?? "Italian"
        
        let sourceCode = getIdentifier(forName: savedSource)
        let targetCode = getIdentifier(forName: savedTarget)
        
        // 3. Create the Configuration
        if configuration == nil {
            configuration = .init(
                source: Locale.Language(identifier: sourceCode),
                target: Locale.Language(identifier: targetCode)
            )
        } else {
            configuration?.invalidate()
        }
    }
    
    
    //To do: the database should contain only the identifier that must be converted when displayed on the screen
    
    private func getIdentifier(forName name: String) -> String {
        // Get all available language codes (en, it, fr, es...)
        let allIds = Locale.availableIdentifiers
        
        // Look for the one that translates to the name we saved
        if let match = allIds.first(where: { id in
            let localizedName = Locale.current.localizedString(forIdentifier: id)
            return localizedName == name
        }) {
            return match // Return "it" if name was "Italian"
        }
        
        return "en" // Fallback to English if not found
    }
}

#Preview {
    TextScannerCameraview()
}


