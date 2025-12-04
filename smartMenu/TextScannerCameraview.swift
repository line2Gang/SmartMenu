import SwiftUI
import VisionKit

struct TextScannerCameraview: View {
    //all scanned item
    @State private var scannedItems: [String] = []
    
    //X button to close the camera
    @State private var showCamera: Bool = false
    
    //used to view the camera view
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
                }
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
                                    .padding(.top, 40) // Adjust for notch
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
}

#Preview {
    TextScannerCameraview()
}
