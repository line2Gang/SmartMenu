import SwiftUI
import VisionKit
import Translation
import SwiftData

struct TextScannerCameraview: View {
    @State private var textViewModel = TextViewModel()
    
    @Environment(\.modelContext) var context
    
    // We REMOVED @Query. The View no longer fetches data directly.
    
    @State private var configuration: TranslationSession.Configuration?
    @State private var showCamera: Bool = false
    @State private var performCapture: Bool = false
    @State private var isProcessing: Bool = false
    
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
                            Text("Menu Items").font(.headline)
                            Spacer()
                            if isProcessing || textViewModel.isProccessing {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("\(textViewModel.scannedItem.count) items").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Show Meals (These will re-order automatically when VM sorts them)
                        if !textViewModel.structuredMeals.isEmpty {
                            ForEach(textViewModel.structuredMeals, id: \.self) { meal in
                                VStack(alignment: .leading) {
                                    Text(meal.name).font(.headline)
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
                        } else {
                            ForEach(textViewModel.scannedItem, id: \.self) { item in
                                Text(item)
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
                Button(action: { showCamera = true }) {
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
        
        // 1. Pass the Context to ViewModel when View appears
        .task {
            textViewModel.setContext(context)
        }
        
        // 2. Translation Task
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
                
                Button(action: { performCapture = true }) {
                    Text("Capture Text")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(30)
                        .padding(.bottom, 50)
                }
            }
            .onChange(of: performCapture) { oldValue, newValue in
                if newValue == false {
                    showCamera = false
                    if !textViewModel.scannedItem.isEmpty {
                        textViewModel.structuredMeals = []
                        triggerTranslation()
                    }
                }
            }
        }
    }
    
    private func triggerTranslation() {
        // We configure the session, but we don't need to pass settings here.
        // The VM handles the actual logic.
        if configuration == nil {
            configuration = .init(
                source: Locale.Language(identifier: "en"),
                target: Locale.Language(identifier: "it")
            )
        } else {
            configuration?.invalidate()
        }
    }
}

#Preview {
    TextScannerCameraview()
}

