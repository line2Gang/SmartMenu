import SwiftUI
import VisionKit

struct TextScannerCameraview: View {
    // State to hold the list of ALL scanned text
    @State private var scannedItems: [String] = []
    
    // State to control showing the camera
    @State private var showCamera: Bool = false
    
    // State to trigger the capture action
    @State private var performCapture: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // --- STATE A: No text scanned yet ---
                if scannedItems.isEmpty {
                    ContentUnavailableView(
                        "No Menu Scanned",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Scan a menu to translate it")
                    )
                }
                // --- STATE B: Text found -> Show List ---
                else {
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
                            
                            // Loop through all scanned items
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
                
                // --- The Main Button ---
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
                .padding()
            }
            .navigationTitle("Smart Menu")
            
            // --- The Camera Modal ---
            .fullScreenCover(isPresented: $showCamera) {
                ZStack(alignment: .bottom) {
                    
                    // 1. The Scanner View
                    DataScanner(
                        recognizedItems: $scannedItems,
                        startScanning: $performCapture
                    )
                    .ignoresSafeArea()
                    
                    // 2. The Capture Button Overlay
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
                                    .padding(.top, 40) // Adjust for notch
                            }
                        }
                        Spacer()
                    }
                }
                // LOGIC: Watch for when capture finishes.
                // When 'performCapture' flips back to false (done by the scanner), we close the camera.
                .onChange(of: performCapture) { oldValue, newValue in
                    if newValue == false {
                        // Capture is done, close the camera!
                        showCamera = false
                    }
                }
            }
        }
    }
}

#Preview {
    TextScannerCameraview()
}
