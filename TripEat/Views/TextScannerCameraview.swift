import SwiftUI
import VisionKit
import Translation
import SwiftData

struct TextScannerCameraview: View {
    // 1. LIFECYCLE: Keep ViewModel alive with @State
    @State private var textViewModel = TextViewModel()
    
    @Environment(\.modelContext) var context
    @State private var configuration: TranslationSession.Configuration?
    
    // 2. UI STATES
    @State private var showCamera: Bool = false
    @State private var performCapture: Bool = false
    
    // Computed properties for the list
    var safeMeals: [Meal] {
        textViewModel.structuredMeals.filter { $0.canEat }
    }
    
    var restrictedMeals: [Meal] {
        textViewModel.structuredMeals.filter { !$0.canEat }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- STATE A: PROCESSING (Loading Animation) ---
            if textViewModel.isProccessing {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(.indigo.gradient)
                        .symbolEffect(.pulse.byLayer, options: .repeating) // iOS 17 Animation
                    
                    Text("AI is analyzing your menu...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
            }
            
            // --- STATE B: EMPTY (Scan Prompt) ---
            else if textViewModel.scannedItem.isEmpty {
                ContentUnavailableView(
                    "No Menu Scanned",
                    systemImage: "doc.text.viewfinder",
                    description: Text("Scan a menu to detect safe meals.")
                )
            }
            
            // --- STATE C: RESULTS LIST ---
            else {
                List {
                    // 1. Safe Meals Section
                    Section {
                        HStack {
                            Text("Safe Options")
                                .font(.headline)
                            Spacer()
                            BadgeView(count: safeMeals.count, color: .green)
                        }
                    }
                    
                    ForEach(safeMeals) { meal in
                        MealRow(meal: meal)
                    }
                    
                    // 2. Restricted Meals Section (Collapsible)
                    if !restrictedMeals.isEmpty {
                        Section {
                            DisclosureGroup {
                                ForEach(restrictedMeals) { meal in
                                    MealRow(meal: meal)
                                }
                            } label: {
                                HStack {
                                    Text("Restricted Items")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    BadgeView(count: restrictedMeals.count, color: .red)
                                }
                            }
                            .tint(.red)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            
            // --- BOTTOM BUTTON (Scan Again) ---
            if !textViewModel.isProccessing {
                VStack {
                    Button(action: { showCamera = true }) {
                        Label(textViewModel.scannedItem.isEmpty ? "Scan Menu" : "Scan Again", systemImage: "camera.fill")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.gradient)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 5)
                    }
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .navigationTitle("Smart Menu")
        .navigationBarTitleDisplayMode(.inline)
        
        // --- LOGIC HOOKS ---
        .task {
            textViewModel.setContext(context)
        }
        .translationTask(configuration) { session in
            await textViewModel.translateAndProcess(using: session)
        }
        
        // --- CAMERA OVERLAY ---
        .fullScreenCover(isPresented: $showCamera) {
            ZStack(alignment: .bottom) {
                // 1. The Scanner View
                DataScanner(
                    recognizedItems: $textViewModel.scannedItem,
                    startScanning: $performCapture
                )
                .ignoresSafeArea()
                
                // 2. YOUR ORIGINAL CAPTURE BUTTON (Restored)
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
                
                // 3. Close Button (Top Right)
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
                    
                    // Wait a tiny bit to ensure the text buffer is filled before translating
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !textViewModel.scannedItem.isEmpty {
                            textViewModel.structuredMeals = [] // Clear old data
                            triggerTranslation()
                        }
                    }
                }
            }
        }
    }
    
    // Helper to start the translation task
    private func triggerTranslation() {
        if configuration == nil {
            configuration = .init(source: .init(identifier: "en"), target: .init(identifier: "it"))
        } else {
            configuration?.invalidate()
        }
    }
}

// MARK: - Subviews

struct MealRow: View {
    let meal: Meal
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(meal.name)
                        .font(.headline)
                        .foregroundStyle(meal.canEat ? .primary : .secondary)
                    
                    if !meal.canEat {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                if !meal.ingredients.isEmpty {
                    Text(meal.ingredients.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Price Display
            if meal.price > 0 {
                Text(String(format: "€%.2f", meal.price))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(meal.canEat ? .blue : .gray)
            }
        }
        .padding(.vertical, 4)
        .opacity(meal.canEat ? 1.0 : 0.6) // Dim restricted items
    }
}

struct BadgeView: View {
    let count: Int
    let color: Color
    
    var body: some View {
        Text("\(count)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.gradient)
            .clipShape(Capsule())
    }
}
#Preview {
    TextScannerCameraview()
}

