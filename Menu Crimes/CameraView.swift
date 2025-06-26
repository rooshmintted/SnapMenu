//
//  CameraView.swift
//  Menu Crimes
//
//  Main camera interface with Snapchat-style UI
//

import SwiftUI
import AVKit

struct CameraView: View {
    let cameraManager: CameraManager
    let galleryManager: PhotoGalleryManager
    let friendManager: FriendManager
    let photoShareManager: PhotoShareManager
    let storyManager: StoryManager
    let menuAnalysisManager: MenuAnalysisManager
    let currentUser: UserProfile
    
    @State private var showingPreview = false
    @State private var showingGalleryPicker = false
    @State private var showingFriendSelection = false
    @State private var showingVideoPreview = false
    
    var body: some View {
        ZStack {
            // Camera preview background
            Color.black.ignoresSafeArea()
            
            if cameraManager.permissionGranted {
                // Camera preview
                CameraPreviewView(captureSession: cameraManager.captureSession, cameraManager: cameraManager)
                    .ignoresSafeArea()
                    .onAppear {
                        print("🎥 CameraView: Camera preview appeared")
                        // Ensure capture session is set up and running
                        if !cameraManager.captureSession.isRunning {
                            print("🎥 CameraView: Setting up and starting camera session")
                            cameraManager.setupCaptureSession()
                        } else {
                            print("🎥 CameraView: Camera session already running")
                        }
                    }
                    .onDisappear {
                        print("🎥 CameraView: Camera preview disappeared, stopping session")
                        cameraManager.stopSession()
                    }
                
                // Camera controls overlay
                VStack {
                    // Top controls
                    HStack {
                        // Gallery access button
                        Button(action: {
                            print("🎥 CameraView: Gallery button tapped")
                            showingGalleryPicker = true
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(.black.opacity(0.3)))
                        }
                        
                        Spacer()
                        
                        // Camera flip button
                        Button(action: {
                            print("🎥 CameraView: Flip camera button tapped")
                            cameraManager.flipCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(.black.opacity(0.3)))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack(spacing: 50) {
                        // Video recording button
                        Button(action: {
                            if cameraManager.isRecording {
                                print("🎥 CameraView: Stop video recording button tapped")
                                cameraManager.stopVideoRecording()
                            } else {
                                print("🎥 CameraView: Start video recording button tapped")
                                cameraManager.startVideoRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(cameraManager.isRecording ? .red : .white.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                
                                if cameraManager.isRecording {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.white)
                                        .frame(width: 20, height: 20)
                                } else {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                        
                        // Photo capture button (main)
                        Button(action: {
                            print("🎥 CameraView: Capture photo button tapped")
                            cameraManager.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(.black, lineWidth: 2)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .fill(.white)
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // Recording indicator
                if cameraManager.isRecording {
                    VStack {
                        HStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 10, height: 10)
                                .scaleEffect(1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(), value: cameraManager.isRecording)
                            
                            Text("REC")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.black.opacity(0.5)))
                        .padding(.top, 50)
                        
                        Spacer()
                    }
                }
            } else {
                // Permission denied state
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Menu Crimes needs camera access to capture menu photos for analysis.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Grant Permission") {
                        print("🎥 CameraView: Grant permission button tapped")
                        cameraManager.requestPermission()
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(.white))
                }
            }
        }
        .sheet(isPresented: $showingGalleryPicker) {
            GalleryPickerView(galleryManager: galleryManager)
        }
        .sheet(isPresented: $showingPreview, onDismiss: {
            // Clear gallery-selected media when preview is dismissed
            if galleryManager.selectedImage != nil {
                galleryManager.clearSelectedMedia()
            }
        }) {
            if let image = cameraManager.capturedImage ?? galleryManager.selectedImage {
                PhotoPreviewView(
                    image: image,
                    friendManager: friendManager,
                    photoShareManager: photoShareManager,
                    storyManager: storyManager,
                    menuAnalysisManager: menuAnalysisManager,
                    currentUser: currentUser
                )
            }
        }
        .sheet(isPresented: $showingVideoPreview, onDismiss: {
            // Clear gallery-selected media when preview is dismissed
            if galleryManager.selectedVideoURL != nil {
                galleryManager.clearSelectedMedia()
            }
        }) {
            if let videoURL = cameraManager.capturedVideoURL ?? galleryManager.selectedVideoURL {
                VideoPreviewView(
                    videoURL: videoURL,
                    friendManager: friendManager,
                    photoShareManager: photoShareManager,
                    storyManager: storyManager,
                    menuAnalysisManager: menuAnalysisManager,
                    currentUser: currentUser
                )
            }
        }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if newImage != nil {
                print("🎥 CameraView: New image captured, showing preview")
                showingPreview = true
            }
        }
        .onChange(of: cameraManager.capturedVideoURL) { _, newVideoURL in
            if newVideoURL != nil {
                print("🎬 CameraView: New video captured, showing preview")
                showingVideoPreview = true
            }
        }
        .onChange(of: galleryManager.selectedImage) { _, newImage in
            if newImage != nil {
                print("📸 CameraView: Photo selected from gallery, showing preview")
                showingGalleryPicker = false // Dismiss gallery picker
                showingPreview = true
            }
        }
        .onChange(of: galleryManager.selectedVideoURL) { _, newVideoURL in
            if newVideoURL != nil {
                print("🎬 CameraView: Video selected from gallery, showing preview")
                showingGalleryPicker = false // Dismiss gallery picker
                showingVideoPreview = true
            }
        }
    }
}

// MARK: - Gallery Picker View
struct GalleryPickerView: View {
    let galleryManager: PhotoGalleryManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if galleryManager.permissionGranted {
                    PhotosPicker(
                        selectedImage: Binding(
                            get: { galleryManager.selectedImage },
                            set: { galleryManager.selectedImage = $0 }
                        ),
                        selectedVideoURL: Binding(
                            get: { galleryManager.selectedVideoURL },
                            set: { galleryManager.selectedVideoURL = $0 }
                        ),
                        isPresented: .constant(true)
                    )
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Photo Library Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if galleryManager.needsSettingsRedirect {
                            Text("Photo access was previously denied. Please enable it in Settings to select photos.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button("Open Settings") {
                                // Open iOS Settings app
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.blue))
                        } else {
                            Text("Grant access to select existing menu photos.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button("Grant Permission") {
                                galleryManager.requestPhotoLibraryPermission()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.blue))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Photo Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Photo Preview View
struct PhotoPreviewView: View {
    let image: UIImage
    let friendManager: FriendManager
    let photoShareManager: PhotoShareManager
    let storyManager: StoryManager
    let menuAnalysisManager: MenuAnalysisManager
    let currentUser: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var showingFriendSelection = false
    @State private var showingAnalysisResult = false
    
    // Filter state management
    @State private var filteredImage: UIImage
    @State private var selectedFilter: PhotoFilter = .none
    @State private var showingFilters = false
    
    // Initialize with original image
    init(image: UIImage, friendManager: FriendManager, photoShareManager: PhotoShareManager, storyManager: StoryManager, menuAnalysisManager: MenuAnalysisManager, currentUser: UserProfile) {
        self.image = image
        self.friendManager = friendManager
        self.photoShareManager = photoShareManager
        self.storyManager = storyManager
        self.menuAnalysisManager = menuAnalysisManager
        self.currentUser = currentUser
        self._filteredImage = State(initialValue: image)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Photo display with current filter applied
                Image(uiImage: filteredImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
                
                // Filter controls overlay
                VStack {
                    Spacer()
                    
                    // Filter toggle button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            print("🎨 PhotoPreviewView: Filter toggle tapped")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFilters.toggle()
                            }
                        }) {
                            Image(systemName: showingFilters ? "camera.filters" : "camera.filters")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(.black.opacity(0.6)))
                        }
                        .padding(.trailing, 20)
                    }
                    
                    // Filter selection buttons
                    if showingFilters {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(PhotoFilter.allCases, id: \.self) { filter in
                                    FilterButton(
                                        filter: filter,
                                        isSelected: selectedFilter == filter,
                                        originalImage: image
                                    ) {
                                        applyFilter(filter)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(height: 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Photo Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Retake") {
                        print("📸 PhotoPreviewView: Retake button tapped")
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {                        
                        Button("Send") {
                            print("📸 PhotoPreviewView: Send button tapped with filter: \(selectedFilter)")
                            showingFriendSelection = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        
                        Button("Analyze Menu") {
                            print("📊 PhotoPreviewView: Analyze menu button tapped")
                            showingAnalysisResult = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFriendSelection) {
            // Send the filtered image, not the original
            FriendSelectionView(
                image: filteredImage, // Using filtered image for sharing
                friendManager: friendManager,
                photoShareManager: photoShareManager,
                storyManager: storyManager,
                currentUser: currentUser
            )
        }
        .sheet(isPresented: $showingAnalysisResult) {
            // Analyze the filtered image, not the original
            MenuAnalysisResultView(
                image: filteredImage, // Using filtered image for analysis
                menuAnalysisManager: menuAnalysisManager,
                currentUser: currentUser,
                onDone: {
                    showingAnalysisResult = false
                }
            )
        }
    }
    
    // MARK: - Filter Application
    private func applyFilter(_ filter: PhotoFilter) {
        print("🎨 PhotoPreviewView: Applying filter: \(filter)")
        selectedFilter = filter
        
        // Apply filter to original image
        if let newFilteredImage = PhotoFilterManager.applyFilter(filter, to: image) {
            filteredImage = newFilteredImage
            print("✅ PhotoPreviewView: Filter \(filter) applied successfully")
        } else {
            print("❌ PhotoPreviewView: Failed to apply filter \(filter)")
            filteredImage = image // Fallback to original
        }
    }
}

// MARK: - Photo Filter Types
enum PhotoFilter: String, CaseIterable {
    case none = "None"
    case vintage = "Vintage"
    case blackAndWhite = "B&W"
    case sepia = "Sepia"
    case dramatic = "Dramatic"
    case vivid = "Vivid"
    case cool = "Cool"
    case warm = "Warm"
    case noir = "Noir"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .none: return "photo"
        case .vintage: return "camera.vintage"
        case .blackAndWhite: return "circle.lefthalf.filled"
        case .sepia: return "sun.max"
        case .dramatic: return "bolt"
        case .vivid: return "paintbrush"
        case .cool: return "snowflake"
        case .warm: return "flame"
        case .noir: return "moon"
        }
    }
}

// MARK: - Filter Button Component
struct FilterButton: View {
    let filter: PhotoFilter
    let isSelected: Bool
    let originalImage: UIImage
    let action: () -> Void
    
    @State private var previewImage: UIImage?
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: action) {
                ZStack {
                    // Preview thumbnail
                    if let preview = previewImage {
                        Image(uiImage: preview)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        // Fallback icon
                        Image(systemName: filter.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(.gray.opacity(0.3)))
                    }
                    
                    // Selection indicator
                    if isSelected {
                        Circle()
                            .stroke(.orange, lineWidth: 3)
                            .frame(width: 54, height: 54)
                    }
                }
            }
            
            Text(filter.displayName)
                .font(.caption2)
                .foregroundColor(.white)
                .frame(maxWidth: 60)
        }
        .onAppear {
            generatePreview()
        }
    }
    
    private func generatePreview() {
        print("🖼️ FilterButton: Generating preview for \(filter)")
        // Create small preview thumbnail for filter button
        let smallImage = originalImage.resized(to: CGSize(width: 100, height: 100))
        
        if filter == .none {
            previewImage = smallImage
        } else {
            previewImage = PhotoFilterManager.applyFilter(filter, to: smallImage) ?? smallImage
        }
    }
}

// MARK: - Photo Filter Manager
class PhotoFilterManager {
    static func applyFilter(_ filter: PhotoFilter, to image: UIImage) -> UIImage? {
        print("🎨 PhotoFilterManager: Applying \(filter) filter to image")
        
        guard filter != .none else {
            print("✅ PhotoFilterManager: No filter selected, returning original")
            return image
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("❌ PhotoFilterManager: Failed to create CIImage from UIImage")
            return nil
        }
        
        let context = CIContext()
        var outputImage: CIImage = ciImage
        
        // Apply the appropriate Core Image filter
        switch filter {
        case .none:
            break
            
        case .vintage:
            // Vintage effect: Sepia + vignette + slight blur
            if let sepiaFilter = CIFilter(name: "CISepiaTone") {
                sepiaFilter.setValue(outputImage, forKey: kCIInputImageKey)
                sepiaFilter.setValue(0.8, forKey: kCIInputIntensityKey)
                outputImage = sepiaFilter.outputImage ?? outputImage
            }
            
            if let vignetteFilter = CIFilter(name: "CIVignette") {
                vignetteFilter.setValue(outputImage, forKey: kCIInputImageKey)
                vignetteFilter.setValue(1.0, forKey: kCIInputIntensityKey)
                vignetteFilter.setValue(2.0, forKey: kCIInputRadiusKey)
                outputImage = vignetteFilter.outputImage ?? outputImage
            }
            
        case .blackAndWhite:
            if let filter = CIFilter(name: "CIPhotoEffectMono") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? outputImage
            }
            
        case .sepia:
            if let filter = CIFilter(name: "CISepiaTone") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                filter.setValue(1.0, forKey: kCIInputIntensityKey)
                outputImage = filter.outputImage ?? outputImage
            }
            
        case .dramatic:
            // High contrast and saturation
            if let contrastFilter = CIFilter(name: "CIColorControls") {
                contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
                contrastFilter.setValue(1.4, forKey: kCIInputContrastKey)
                contrastFilter.setValue(1.2, forKey: kCIInputSaturationKey)
                outputImage = contrastFilter.outputImage ?? outputImage
            }
            
        case .vivid:
            if let filter = CIFilter(name: "CIPhotoEffectVivid") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? outputImage
            }
            
        case .cool:
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                filter.setValue(CIVector(x: 6500, y: 50), forKey: "inputTargetNeutral")
                outputImage = filter.outputImage ?? outputImage
            }
            
        case .warm:
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                filter.setValue(CIVector(x: 6500, y: -50), forKey: "inputTargetNeutral")
                outputImage = filter.outputImage ?? outputImage
            }
            
        case .noir:
            // Black and white with high contrast
            if let bwFilter = CIFilter(name: "CIPhotoEffectNoir") {
                bwFilter.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = bwFilter.outputImage ?? outputImage
            }
        }
        
        // Convert back to UIImage
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("❌ PhotoFilterManager: Failed to create CGImage from filtered CIImage")
            return nil
        }
        
        let filteredUIImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        print("✅ PhotoFilterManager: Successfully applied \(filter) filter")
        return filteredUIImage
    }
}

// MARK: - UIImage Extension for Resizing
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(
            cameraManager: CameraManager(),
            galleryManager: PhotoGalleryManager(),
            friendManager: FriendManager(authManager: AuthManager()),
            photoShareManager: PhotoShareManager(),
            storyManager: StoryManager(),
            menuAnalysisManager: MenuAnalysisManager(),
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
