//
//  StoryView.swift
//  Menu Crimes
//
//  View for displaying and navigating through user stories
//

import SwiftUI
import AVKit

struct StoryView: View {
    let stories: [Story]
    let username: String
    let storyManager: StoryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStoryIndex = 0
    @State private var progressValues: [Double] = []
    @State private var timer: Timer?
    @State private var player: AVPlayer?
    @State private var showingDeleteAlert = false
    @State private var storyToDelete: Story?
    
    // **Rule Applied**: Add debug logs for easier debug & readability
    
    var currentStory: Story? {
        guard currentStoryIndex < stories.count else { return nil }
        return stories[currentStoryIndex]
    }
    
    var isCurrentUserStory: Bool {
        // Check if this is the current user's story (they can delete it)
        guard let currentStory = currentStory else { return false }
        return currentStory.userId == storyManager.getCurrentUserId()
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if stories.isEmpty {
                VStack {
                    Text("No stories available")
                        .foregroundColor(.white)
                        .font(.title2)
                    
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .padding(.top)
                }
            } else if let story = currentStory {
                // Story content
                Group {
                    if story.mediaType == .photo {
                        AsyncImage(url: URL(string: storyManager.getPublicURL(for: story))) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure(let error):
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.yellow)
                                        .font(.title)
                                    Text("Failed to load image")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                    Text("URL: \(story.mediaUrl)")
                                        .foregroundColor(.gray)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    Text("Error: \(error.localizedDescription)")
                                        .foregroundColor(.red)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding()
                            case .empty:
                                VStack {
                                    ProgressView()
                                        .foregroundColor(.white)
                                    Text("Loading image...")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .padding(.top)
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
                                    print("📱 StoryView: Starting video playback for story \(story.id)")
                                    player.play()
                                }
                        } else {
                            VStack {
                                ProgressView("Loading video...")
                                    .foregroundColor(.white)
                                Text("Preparing video player...")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .padding(.top)
                                Text("URL: \(story.mediaUrl)")
                                    .foregroundColor(.gray)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .onTapGesture { location in
                    // Tap left side = previous, right side = next
                    let width = UIScreen.main.bounds.width
                    if location.x < width / 2 {
                        previousStory()
                    } else {
                        nextStory()
                    }
                }
                
                // Story progress bars at top
                VStack {
                    HStack(spacing: 2) {
                        ForEach(0..<stories.count, id: \.self) { index in
                            ProgressView(value: progressValues.indices.contains(index) ? progressValues[index] : 0.0, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                .scaleEffect(y: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
                    Spacer()
                }
                
                // Header with user info and close button
                VStack {
                    HStack {
                        // User info
                        HStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(username.prefix(1).uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(username)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text(story.timeAgo)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // Action buttons
                        HStack(spacing: 16) {
                            // Delete button (only for current user's stories)
                            if isCurrentUserStory {
                                Button(action: {
                                    print("🗑️ StoryView: Delete button tapped for story \(story.id)")
                                    storyToDelete = story
                                    showingDeleteAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                }
                            }
                            
                            // Close button
                            Button(action: {
                                print("❌ StoryView: Close button tapped")
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Caption overlay
                    if let caption = story.caption, !caption.isEmpty {
                        VStack {
                            Spacer()
                            Text(caption)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .padding(.bottom, 100)
                        }
                    }
                }
            } else {
                Text("No stories available")
                    .foregroundColor(.white)
                    .font(.title2)
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .onAppear {
            print("📱 StoryView: Appeared with \(stories.count) stories for user \(username)")
            print("📱 StoryView: First story URL: \(stories.first?.mediaUrl ?? "none")")
            guard !stories.isEmpty else {
                print("❌ StoryView: No stories to display")
                return
            }
            
            setupProgressBars()
            setupCurrentStory()
            startTimer()
        }
        .onDisappear {
            print("📱 StoryView: Disappeared, cleaning up")
            stopTimer()
            cleanupPlayer()
        }
        .alert("Delete Story", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let story = storyToDelete {
                    deleteStory(story)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this story? This action cannot be undone.")
        }
    }
    
    // MARK: - Story Navigation
    
    private func nextStory() {
        print("➡️ StoryView: Moving to next story (current: \(currentStoryIndex))")
        stopTimer()
        
        guard !stories.isEmpty else {
            print("❌ StoryView: No stories to navigate to")
            dismiss()
            return
        }
        
        if currentStoryIndex < stories.count - 1 {
            currentStoryIndex += 1
            setupCurrentStory()
            startTimer()
        } else {
            // End of stories, dismiss
            print("📱 StoryView: Reached end of stories, dismissing")
            dismiss()
        }
    }
    
    private func previousStory() {
        print("⬅️ StoryView: Moving to previous story (current: \(currentStoryIndex))")
        stopTimer()
        
        guard !stories.isEmpty else {
            print("❌ StoryView: No stories to navigate to")
            dismiss()
            return
        }
        
        if currentStoryIndex > 0 {
            currentStoryIndex -= 1
            setupCurrentStory()
            startTimer()
        } else {
            print("📱 StoryView: Already at first story")
            setupCurrentStory()
            startTimer()
        }
    }
    
    // MARK: - Progress & Timer Management
    
    private func setupProgressBars() {
        guard !stories.isEmpty else {
            print("❌ StoryView: Cannot setup progress bars for empty stories")
            return
        }
        
        progressValues = Array(repeating: 0.0, count: stories.count)
        
        // Mark previous stories as complete
        for i in 0..<currentStoryIndex {
            if i < progressValues.count {
                progressValues[i] = 1.0
            }
        }
        
        print("📊 StoryView: Setup progress bars for \(stories.count) stories")
    }
    
    private func startTimer() {
        guard let story = currentStory else {
            print("❌ StoryView: Cannot start timer - no current story")
            return
        }
        
        // Stop any existing timer first
        stopTimer()
        
        let duration: Double = story.mediaType == .video ? Double(story.durationSeconds ?? 10) : 5.0
        let updateInterval: Double = 0.1
        let totalUpdates = duration / updateInterval
        
        print("⏱️ StoryView: Starting timer for story \(story.id) with duration \(duration)s")
        
        var updateCount = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            updateCount += 1
            let progress = updateCount / totalUpdates
            
            // Ensure we don't go out of bounds
            if self.currentStoryIndex < self.progressValues.count {
                self.progressValues[self.currentStoryIndex] = min(progress, 1.0)
            }
            
            if progress >= 1.0 {
                self.nextStory()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Media Setup
    
    private func setupCurrentStory() {
        guard let story = currentStory else { 
            print("❌ StoryView: No current story to setup")
            return 
        }
        
        print("🎬 StoryView: Setting up story \(story.id) of type \(story.mediaType)")
        print("🔗 StoryView: Media URL: \(story.mediaUrl)")
        
        cleanupPlayer()
        
        if story.mediaType == .video {
            guard let url = URL(string: storyManager.getPublicURL(for: story)) else {
                print("❌ StoryView: Invalid media URL for story \(story.id): \(story.mediaUrl)")
                return
            }
            
            print("🎥 StoryView: Creating AVPlayer with URL: \(url)")
            player = AVPlayer(url: url)
            player?.isMuted = false
            
            // Monitor player status for debugging
            if let playerItem = player?.currentItem {
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: playerItem,
                    queue: .main
                ) { _ in
                    print("🎥 StoryView: Video finished playing")
                }
            }
        } else {
            print("📸 StoryView: Photo story - no player setup needed")
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
    }
    
    // MARK: - Story Management
    
    private func deleteStory(_ story: Story) {
        print("🗑️ StoryView: Deleting story \(story.id)")
        
        Task {
            await storyManager.deleteStory(story)
            
            await MainActor.run {
                // If this was the only story, dismiss
                if stories.count <= 1 {
                    dismiss()
                } else {
                    // Move to next story or previous if at end
                    if currentStoryIndex >= stories.count - 1 {
                        currentStoryIndex = max(0, stories.count - 2)
                    }
                    setupCurrentStory()
                    startTimer()
                }
            }
        }
    }
}

// MARK: - Story Extensions

extension Story {
    var timeAgo: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else { // Hours
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        }
    }
}

#Preview {
    StoryView(
        stories: [
            Story(
                id: UUID(),
                userId: UUID(),
                mediaUrl: "https://example.com/story1.jpg",
                mediaType: .photo,
                durationSeconds: nil,
                caption: "My awesome story!",
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                expiresAt: Date().addingTimeInterval(23*3600) // 23 hours from now
            )
        ],
        username: "testuser",
        storyManager: StoryManager()
    )
}
