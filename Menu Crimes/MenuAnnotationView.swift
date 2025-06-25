//
//  MenuAnnotationView.swift
//  Menu Crimes
//
//  View for displaying annotated menu with margin analysis
//

import SwiftUI

struct MenuAnnotationView: View {
    let annotationManager: MenuAnnotationManager
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if annotationManager.isLoading {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Generating Menu Analysis...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Using Apple Vision to detect dishes and annotate margins")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else if let error = annotationManager.error {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Analysis Failed")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            Task {
                                await annotationManager.generateAnnotatedImage()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let imageData = annotationManager.annotatedImageData,
                          let uiImage = UIImage(data: imageData) {
                    // Show annotated image with basic zoom/pan
                    FullScreenImageView(image: uiImage)
                } else {
                    // Initial state
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("Menu Analysis Ready")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Tap 'Generate Analysis' to detect dishes and annotate with intelligent margin analysis")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Generate Analysis") {
                            Task {
                                await annotationManager.generateAnnotatedImage()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                }
            }
            .navigationTitle("Menu Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareAnnotatedImage()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Load menu analysis data if not already loaded
            if annotationManager.menuAnalysisData == nil {
                annotationManager.loadMenuAnalysis()
            }
        }
    }
    
    private func shareAnnotatedImage() {
        guard let imageData = annotationManager.annotatedImageData,
              let image = UIImage(data: imageData) else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first else {
            return
        }
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        window.rootViewController?.present(activityVC, animated: true)
        
        print("📊 MenuAnnotationView: Sharing annotated menu analysis image")
    }
}

// MARK: - Basic Full Screen Image View
struct FullScreenImageView: View {
    let image: UIImage
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let magnification = value / lastMagnification
                                scale *= magnification
                                scale = max(1.0, min(scale, 5.0))
                                lastMagnification = value
                            }
                            .onEnded { _ in
                                lastMagnification = 1.0
                            },
                        
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                            }
                            .onEnded { _ in
                                // Optional: Add bounds checking here if needed
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
        }
    }
}

// MARK: - Preview
#Preview {
    MenuAnnotationView(annotationManager: MenuAnnotationManager())
}
