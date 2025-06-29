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
                Color(.systemBackground).ignoresSafeArea()
                
                if annotationManager.isLoading {
                    // Premium loading state
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                                .opacity(0.2)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                .scaleEffect(1.8)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Generating AI Analysis")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Using Apple Vision to detect dishes and annotate profit margins")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                } else if let error = annotationManager.error {
                    // Premium error state
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.red)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Analysis Failed")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(error)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        Button(action: {
                            Task {
                                await annotationManager.generateAnnotatedImage()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Try Again")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding()
                } else if let imageData = annotationManager.annotatedImageData,
                          let uiImage = UIImage(data: imageData) {
                    // Show annotated image with basic zoom/pan
                    FullScreenImageView(image: uiImage)
                } else {
                    // Premium initial state
                    VStack(spacing: 32) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 16) {
                            Text("AI Analysis Ready")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Tap 'Generate Analysis' to detect dishes and annotate with intelligent profit margin insights")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        Button(action: {
                            Task {
                                await annotationManager.generateAnnotatedImage()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Generate Analysis")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding()
                }
            }
            .navigationTitle("Menu AI Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareAnnotatedImage()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .disabled(annotationManager.annotatedImageData == nil)
                    .opacity(annotationManager.annotatedImageData == nil ? 0.5 : 1.0)
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
        // Debug: Check if we have an annotated image to share
        guard let imageData = annotationManager.annotatedImageData,
              let image = UIImage(data: imageData) else {
            print("❌ MenuAnnotationView: No annotated image available for sharing")
            return
        }
        
        print("📊 MenuAnnotationView: Preparing to share annotated menu image")
        
        // Create activity items - include both the image and a descriptive title
        let shareTitle = "Menu Analysis - Restaurant Dish Margins"
        let activityItems: [Any] = [image, shareTitle]
        
        // Create UIActivityViewController with comprehensive sharing options
        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Configure activity types to exclude (if any)
        // Uncomment the line below if you want to exclude certain sharing options
        // activityVC.excludedActivityTypes = [.addToReadingList, .assignToContact]
        
        // Handle iPad popover presentation
        if let popover = activityVC.popoverPresentationController {
            // Try to get the share button's view for better popover positioning
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window
                // Position popover in the top-right area where the share button is
                let buttonRect = CGRect(
                    x: window.bounds.maxX - 60,
                    y: window.safeAreaInsets.top + 44,
                    width: 44,
                    height: 44
                )
                popover.sourceRect = buttonRect
                popover.permittedArrowDirections = [.up]
                
                print("📊 MenuAnnotationView: Configured iPad popover presentation")
            } else {
                // Fallback positioning
                popover.sourceView = nil
                popover.sourceRect = CGRect(x: 0, y: 0, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Find the top-most presented view controller
            var topViewController = rootViewController
            while let presented = topViewController.presentedViewController {
                topViewController = presented
            }
            
            topViewController.present(activityVC, animated: true) {
                print("✅ MenuAnnotationView: Successfully presented share sheet")
            }
        } else {
            print("❌ MenuAnnotationView: Could not find root view controller for presenting share sheet")
        }
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
