import SwiftUI
import VisionKit
import Translation
import SwiftData

struct TextScannerCameraView: View {
    
    @Environment(\.modelContext)
    var context
    @Environment(UserController.self)
    var userController
    @Environment(TranslationController.self)
    var translationController
    @Environment(AnalyserController.self)
    var analyserController
    
    @State
    private var textViewModel = TextViewModel()
    @State
    private var showCamera: Bool = false
    @State
    private var performCapture: Bool = false
    @State
    private var isProcessing: Bool = false
    @State
    private var userProfilIsPresented: Bool = false
    @State
    var contentScanned: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if self.contentScanned.isEmpty {
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
                                if isProcessing {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text("\(self.contentScanned.count) items").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
//                            // Show Meals (These will re-order automatically when VM sorts them)
//                            if !self.contentScanned.isEmpty {
//                                ForEach(textViewModel.structuredMeals, id: \.self) { meal in
//                                    VStack(alignment: .leading) {
//                                        Text(meal.name).font(.headline)
//                                        if !meal.ingredients.isEmpty {
//                                            Text(meal.ingredients.joined(separator: ", "))
//                                                .font(.subheadline)
//                                                .foregroundStyle(.secondary)
//                                        }
//                                    }
//                                    .padding()
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                    .background(Color.green.opacity(0.1))
//                                    .cornerRadius(12)
//                                    .padding(.horizontal)
//                                }
//                            } else {
//                                ForEach(textViewModel.scannedItem, id: \.self) { item in
//                                    Text(item)
//                                        .padding()
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .background(Color.gray.opacity(0.1))
//                                        .cornerRadius(12)
//                                        .padding(.horizontal)
//                                }
//                            }
                        }
                        .padding(.top)
                    }
                }
                Spacer()
                VStack {
                    HStack(spacing: 12) {
                        Button(action: { showCamera = true }) {
                            Label(self.contentScanned.isEmpty ? "Scan Menu" : "Scan Again", systemImage: "camera.fill")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        Button {
                            self.userProfilIsPresented = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    }
                    .padding()
                    Button {
                        Task {
                          await translationController.translate(sourceText: self.contentScanned)
                            if !translationController.translatedText.isEmpty {
                                await analyserController.extractMenu(from: translationController.translatedText)
                                if let user = userController.currentUser {
                                    await analyserController.sortMenu(regarding: user)
                                }
                            }
                        }
                    } label: {
                        
                    }
                }
            }
            .navigationTitle("Smart Menu")
            .navigationBarTitleDisplayMode(.inline)
            // Manage the display of the UserProfilView
            .onAppear {
                if userController.users.isEmpty {
                    self.userProfilIsPresented = true
                }
            }
            // Get the environment context for swiftData and launch the first fetch
            .task {
                userController.context = self.context
                userController.getUsers()
            }
            // UserProfilView
            .sheet(isPresented: $userProfilIsPresented) {
                UserProfilView(isPresented: self.$userProfilIsPresented)
            }
            // Camera View
            .fullScreenCover(isPresented: $showCamera) {
                ZStack(alignment: .bottom) {
                    DataScanner(
                        recognizedItems: self.$contentScanned,
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
                        if !self.$contentScanned.isEmpty {
                            self.contentScanned.removeAll()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    
    @Previewable
    var translationController = TranslationController()
    @Previewable
    var analyserController = AnalyserController()
    @Previewable
    var userController = UserController()
    
    TextScannerCameraView()
        .modelContainer(for: User.self)
        .environment(translationController)
        .environment(userController)
        .environment(analyserController)
    
}

