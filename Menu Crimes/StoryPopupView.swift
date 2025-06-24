//
//  StoryPopupView.swift
//  Menu Crimes
//
//  Simple popup view for displaying stories
//

import SwiftUI
import AVKit

struct StoryPopupView: View {
    let stories: [Story]
    let username: String
    let storyManager: StoryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex = 0
    @State private var progress: Double = 0.0
    @State private var timer: Timer?
    @State private var player: AVPlayer?
    
    var currentStory: Story? {
        guard currentIndex < stories.count else { return nil }
        return stories[currentIndex]
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            if let story = currentStory {
                VStack(spacing: 0) {
                    // Progress bar
                    HStack(spacing: 4) {
                        ForEach(0..<stories.count, id: \.self) { index in
                            Rectangle()
                                .fill(index < currentIndex ? Color.white : 
                                      index == currentIndex ? Color.white.opacity(progress) : 
                                      Color.white.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 50)
                    
                    // Header
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(username.prefix(2).uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(username)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(story.timeAgo)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Story content
                    GeometryReader { geometry in
                        ZStack {
                            if story.mediaType == .photo {
                                // Photo story
                                AsyncImage(url: URL(string: storyManager.getPublicURL(for: story))) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    case .failure(let error):
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 50))
                                                .foregroundColor(.white.opacity(0.5))
                                            
                                            Text("Failed to load photo")
                                                .foregroundColor(.white)
                                                .font(.headline)
                                            
                                            Text(error.localizedDescription)
                                                .foregroundColor(.white.opacity(0.7))
                                                .font(.caption)
                                                .multilineTextAlignment(.center)
                                        }
                                    case .empty:
                                        VStack(spacing: 12) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            Text("Loading...")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                // Video story
                                if let player = player {
                                    VideoPlayer(player: player)
                                        .onAppear {
                                            print("🎥 StoryPopupView: Starting video playback")
                                            player.play()
                                        }
                                } else {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("Loading video...")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            // Tap areas for navigation
                            HStack(spacing: 0) {
                                // Left tap area - previous story
                                Rectangle()
                                    .fill(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        previousStory()
                                    }
                                
                                // Right tap area - next story
                                Rectangle()
                                    .fill(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        nextStory()
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Caption (if present)
                    if let caption = story.caption, !caption.isEmpty {
                        Text(caption)
                            .foregroundColor(.white)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Color.black.opacity(0.3)
                                    .cornerRadius(12)
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 50)
                    } else {
                        Spacer()
                            .frame(height: 50)
                    }
                }
            } else {
                // No stories
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("No Stories")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            print("📱 StoryPopupView: Appeared with \(stories.count) stories for \(username)")
            startStoryTimer()
        }
        .onDisappear {
            stopTimer()
            cleanupPlayer()
        }
        .onChange(of: currentIndex) { _, newIndex in
            setupCurrentStory()
        }
    }
    
    // MARK: - Navigation
    
    private func nextStory() {
        stopTimer()
        
        if currentIndex < stories.count - 1 {
            currentIndex += 1
            progress = 0.0
            startStoryTimer()
        } else {
            dismiss()
        }
    }
    
    private func previousStory() {
        stopTimer()
        
        if currentIndex > 0 {
            currentIndex -= 1
            progress = 0.0
            startStoryTimer()
        }
    }
    
    // MARK: - Timer Management
    
    private func startStoryTimer() {
        guard let story = currentStory else { return }
        
        stopTimer()
        setupCurrentStory()
        
        let duration: Double = story.mediaType == .video ? Double(story.durationSeconds ?? 10) : 5.0
        let updateInterval: Double = 0.1
        let totalUpdates = duration / updateInterval
        
        print("⏱️ StoryPopupView: Starting timer for \(duration)s")
        
        var updateCount = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            updateCount += 1
            progress = updateCount / totalUpdates
            
            if progress >= 1.0 {
                nextStory()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Media Setup
    
    private func setupCurrentStory() {
        guard let story = currentStory else { return }
        
        print("🎬 StoryPopupView: Setting up story \(story.mediaType)")
        
        cleanupPlayer()
        
        if story.mediaType == .video {
            let urlString = storyManager.getPublicURL(for: story)
            guard let url = URL(string: urlString) else {
                print("❌ StoryPopupView: Invalid video URL: \(urlString)")
                return
            }
            
            print("🎥 StoryPopupView: Creating player with URL: \(url)")
            player = AVPlayer(url: url)
            player?.isMuted = false
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
    }
}

#Preview {
    // Create a mock story for preview
    let mockStory = Story(
        id: UUID(),
        userId: UUID(), 
        mediaUrl: "https://example.com/story.jpg",
        mediaType: .photo,
        durationSeconds: nil,
        caption: "Test story caption",
        createdAt: Date().addingTimeInterval(-1800), // 30 minutes ago
        expiresAt: Date().addingTimeInterval(22*3600) // expires in 22 hours
    )
    
    StoryPopupView(
        stories: [mockStory],
        username: "testuser",
        storyManager: StoryManager()
    )
}
