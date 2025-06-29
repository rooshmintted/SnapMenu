//
//  CameraView.swift
//  Menu Crimes
//
//  Main camera interface for menu photo capture and analysis
//

import SwiftUI
import AVKit
import AVFoundation

struct CameraView: View {
    let cameraManager: CameraManager
    let galleryManager: PhotoGalleryManager
    let menuAnalysisManager: MenuAnalysisManager
    let menuAnnotationManager: MenuAnnotationManager
    let currentUser: UserProfile
    
    @State private var showingPreview = false
    @State private var showingGalleryPicker = false
    
    // Computed properties to simplify complex expressions
    private var captureButtonGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, .red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var galleryButtonStyle: some View {
        Circle()
            .fill(Color.black.opacity(0.6))
            .frame(width: 56, height: 56)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var captureButtonBase: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 80, height: 80)
            .overlay(
                Circle()
                    .stroke(captureButtonGradient, lineWidth: 4)
            )
    }
    
    // Break down the camera preview setup
    private func setupCameraPreview() -> some View {
        CameraPreviewView(captureSession: cameraManager.captureSession, cameraManager: cameraManager)
            .ignoresSafeArea()
            .onAppear {
                handleCameraPreviewAppear()
            }
            .onDisappear {
                handleCameraPreviewDisappear()
            }
    }
    
    // Extract camera preview event handlers
    private func handleCameraPreviewAppear() {
        print("📸 CameraView: Camera preview appeared")
        if !cameraManager.captureSession.isRunning {
            print("📸 CameraView: Setting up and starting camera session")
            cameraManager.setupCaptureSession()
        } else {
            print("📸 CameraView: Camera session already running")
        }
    }
    
    private func handleCameraPreviewDisappear() {
        print("📸 CameraView: Camera preview disappeared, stopping session")
        cameraManager.stopSession()
    }
    
    // Simplify gallery button creation
    private func createGalleryButton() -> some View {
        VStack(spacing: 12) {
            if galleryManager.needsSettingsRedirect {
                createSettingsButton()
                createButtonLabel(text: "Settings")
            } else {
                createGalleryAccessButton()
                createButtonLabel(text: "Gallery")
            }
        }
    }
    
    private func createSettingsButton() -> some View {
        Button(action: openSettings) {
            ZStack {
                galleryButtonStyle
                Image(systemName: "gear")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    private func createGalleryAccessButton() -> some View {
        Button(action: requestPhotoLibraryAccess) {
            ZStack {
                galleryButtonStyle
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    private func createButtonLabel(text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
    }
    
    // Extract action handlers
    private func openSettings() {
        print("📱 CameraView: Opening Settings for photo library access")
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    private func requestPhotoLibraryAccess() {
        print("📱 CameraView: Requesting photo library permission")
        galleryManager.requestPhotoLibraryPermission()
    }
    
    // Simplify capture button
    private func createCaptureButton() -> some View {
        Button(action: capturePhoto) {
            captureButtonBase
        }
    }
    
    private func capturePhoto() {
        print("📸 CameraView: Capture button tapped")
        cameraManager.capturePhoto()
    }
    
    // Create camera controls overlay - capture button now at bottom center
    private func createCameraControls() -> some View {
        VStack {
            // Gallery button positioned at top left
            HStack {
                createGalleryButton()
                Spacer()
            }
            .padding(.top, 60) // Position gallery button below navigation bar
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Capture button centered at bottom above tab bar
            HStack {
                Spacer()
                createCaptureButton()
                Spacer()
            }
            .padding(.bottom, 100) // Position above tab bar with sufficient spacing
        }
    }
    
    // Create permission prompt
    private func createPermissionPrompt() -> some View {
        VStack(spacing: 32) {
            createPermissionIcon()
            createPermissionText()
            createPermissionButton()
        }
    }
    
    private func createPermissionIcon() -> some View {
        ZStack {
            Circle()
                .fill(captureButtonGradient)
                .frame(width: 100, height: 100)
            
            Image(systemName: "camera")
                .font(.system(size: 50, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func createPermissionText() -> some View {
        VStack(spacing: 16) {
            Text("Ready to Discover Menus?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Capture restaurant menus to unlock AI-powered insights, pricing analysis, and intelligent dish discovery.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private func createPermissionButton() -> some View {
        Button("Enable Camera") {
            // Request camera permission through the camera manager
            // You'll need to implement this method in CameraManager or handle it differently
            Task {
                await AVCaptureDevice.requestAccess(for: .video)
                // Optionally refresh the permission state
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(captureButtonGradient)
        .cornerRadius(16)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if cameraManager.permissionGranted {
                    setupCameraPreview()
                    createCameraControls()
                } else {
                    createPermissionPrompt()
                }
            }
            .navigationTitle("Take a Photo of a Menu")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingGalleryPicker) {
                GalleryPickerView(galleryManager: galleryManager)
            }
            .sheet(isPresented: $showingPreview, onDismiss: handlePreviewDismiss) {
                createPhotoPreview()
            }
            .onChange(of: cameraManager.capturedImage) { _, newPhoto in
                handleCapturedImageChange(newPhoto)
            }
            .onChange(of: galleryManager.selectedImage) { _, newImage in
                handleSelectedImageChange(newImage)
            }
        }
    }
    
    // Extract sheet content and handlers
    private func createPhotoPreview() -> some View {
        Group {
            if let image = cameraManager.capturedImage ?? galleryManager.selectedImage {
                PhotoPreviewView(
                    image: image,
                    menuAnalysisManager: menuAnalysisManager,
                    menuAnnotationManager: menuAnnotationManager,
                    currentUser: currentUser,
                    onDone: handlePreviewDone
                )
            }
        }
    }
    
    private func handlePreviewDismiss() {
        if cameraManager.capturedImage != nil {
            cameraManager.capturedImage = nil
        }
        if galleryManager.selectedImage != nil {
            galleryManager.clearSelectedMedia()
        }
    }
    
    private func handlePreviewDone() {
        print("📸 CameraView: Photo preview done, dismissing")
        showingPreview = false
    }
    
    private func handleCapturedImageChange(_ newPhoto: UIImage?) {
        if newPhoto != nil {
            print("📸 CameraView: Photo captured, showing preview")
            showingPreview = true
        }
    }
    
    private func handleSelectedImageChange(_ newImage: UIImage?) {
        if newImage != nil {
            print("📸 CameraView: Photo selected from gallery, showing preview")
            showingGalleryPicker = false
            showingPreview = true
        }
    }
}

// MARK: - Gallery Picker View
struct GalleryPickerView: View {
    let galleryManager: PhotoGalleryManager
    @Environment(\.dismiss) private var dismiss
    
    // Computed bindings to simplify PhotosPicker expressions
    private var selectedImageBinding: Binding<UIImage?> {
        Binding(
            get: { galleryManager.selectedImage },
            set: { galleryManager.selectedImage = $0 }
        )
    }
    
    private var selectedVideoURLBinding: Binding<URL?> {
        Binding(
            get: { galleryManager.selectedVideoURL },
            set: { galleryManager.selectedVideoURL = $0 }
        )
    }
    
    private var permissionDeniedContent: some View {
        VStack(spacing: 32) {
            createGalleryPermissionIcon()
            createGalleryPermissionText()
            createGalleryPermissionButton()
        }
    }
    
    private func createGalleryPermissionIcon() -> some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 100, height: 100)
            
            Image(systemName: "camera")
                .font(.system(size: 50, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func createGalleryPermissionText() -> some View {
        VStack(spacing: 16) {
            Text("Camera Access Required")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Menu AI needs camera access to analyze and understand your menu photos with intelligence.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private func createGalleryPermissionButton() -> some View {
        Button("Enable Camera Access") {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if galleryManager.permissionGranted {
                    PhotosPicker(
                        selectedImage: selectedImageBinding,
                        selectedVideoURL: selectedVideoURLBinding,
                        isPresented: .constant(true)
                    )
                } else {
                    permissionDeniedContent
                }
            }
            .navigationTitle("Menu AI Camera")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Photo Preview View
struct PhotoPreviewView: View {
    let image: UIImage
    let menuAnalysisManager: MenuAnalysisManager
    let menuAnnotationManager: MenuAnnotationManager
    let currentUser: UserProfile
    let onDone: () -> Void
    
    @State private var showingAnalysisResult = false
    @State private var isAnalyzing = false
    
    private func createAnalysisButton() -> some View {
        Button(action: analyzeMenu) {
            HStack(spacing: 12) {
                if isAnalyzing {
                    createAnalysisProgressView()
                } else {
                    createAnalysisIcon()
                }
                createAnalysisButtonText()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(createAnalysisButtonBackground())
            .cornerRadius(16)
        }
        .disabled(isAnalyzing)
        .scaleEffect(isAnalyzing ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isAnalyzing)
        .padding(.trailing, 24)
    }
    
    private func createAnalysisProgressView() -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(0.9)
    }
    
    private func createAnalysisIcon() -> some View {
        Image(systemName: "sparkles")
            .font(.system(size: 16, weight: .medium))
    }
    
    private func createAnalysisButtonText() -> some View {
        Text(isAnalyzing ? "Analyzing Menu..." : "Analyze with AI")
            .font(.system(size: 18, weight: .semibold))
    }
    
    private func createAnalysisButtonBackground() -> LinearGradient {
        if isAnalyzing {
            return LinearGradient(
                colors: [.gray.opacity(0.8), .gray],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        createAnalysisButton()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Menu Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Retake") {
                        print("📸 PhotoPreviewView: Retake button tapped")
                        onDone()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("📸 PhotoPreviewView: Done button tapped")
                        onDone()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingAnalysisResult) {
            MenuAnalysisResultView(
                image: image,
                menuAnalysisManager: menuAnalysisManager,
                menuAnnotationManager: menuAnnotationManager,
                currentUser: currentUser,
                onDone: {
                    showingAnalysisResult = false
                }
            )
        }
    }
    
    private func analyzeMenu() {
        isAnalyzing = true
        Task {
            await menuAnalysisManager.analyzeMenu(image: image, currentUser: currentUser)
            await MainActor.run {
                isAnalyzing = false
                showingAnalysisResult = true
            }
        }
    }
}

// MARK: - Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(
            cameraManager: CameraManager(),
            galleryManager: PhotoGalleryManager(),
            menuAnalysisManager: MenuAnalysisManager(),
            menuAnnotationManager: MenuAnnotationManager(),
            currentUser: UserProfile(
                id: UUID(),
                username: "testuser",
                avatarUrl: nil,
                website: nil,
                updatedAt: Date()
            )
        )
    }
}
