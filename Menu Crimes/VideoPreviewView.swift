//
//  VideoPreviewView.swift
//  Menu Crimes
//
//  Video preview view for recorded videos with send functionality
//

import SwiftUI
import AVKit

struct VideoPreviewView: View {
    let videoURL: URL
    let friendManager: FriendManager
    let photoShareManager: PhotoShareManager
    let storyManager: StoryManager
    let menuAnalysisManager: MenuAnalysisManager
    let pollManager: PollManager
    let currentUser: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var showingFriendSelection = false
    @State private var player: AVPlayer?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Video player
                if let player = player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onAppear {
                            // Debug logging for video player
                            print("🎬 VideoPreviewView: Video player appeared, starting playback")
                            player.play()
                        }
                        .onDisappear {
                            // Debug logging and cleanup
                            print("🎬 VideoPreviewView: Video player disappeared, pausing playback")
                            player.pause()
                        }
                } else {
                    ProgressView("Loading video...")
                        .foregroundColor(.white)
                }
            }
            .navigationTitle("Video Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Retake") {
                        print("🎬 VideoPreviewView: Retake button tapped")
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Use Video") {
                            print("🎬 VideoPreviewView: Use video button tapped")
                            // TODO: Implement video processing/analysis
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        
                        Button("Send") {
                            print("🎬 VideoPreviewView: Send button tapped - opening friend selection")
                            showingFriendSelection = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            // Debug logging for video setup
            print("🎬 VideoPreviewView: Setting up video player for URL: \(videoURL)")
            setupVideoPlayer()
        }
        .onDisappear {
            // Cleanup player
            print("🎬 VideoPreviewView: Cleaning up video player")
            player?.pause()
            player = nil
        }
        .sheet(isPresented: $showingFriendSelection) {
            // Use the unified FriendSelectionView for videos (same as photos)
            FriendSelectionView(
                videoURL: videoURL,
                friendManager: friendManager,
                photoShareManager: photoShareManager,
                storyManager: storyManager,
                currentUser: currentUser
            )
        }
    }
    
    private func setupVideoPlayer() {
        // Debug logging for player setup
        print("🎬 VideoPreviewView: Creating AVPlayer with video URL")
        player = AVPlayer(url: videoURL)
        
        // Configure player for optimal preview experience
        if let player = player {
            player.isMuted = false
            print("🎬 VideoPreviewView: Player configured successfully")
        } else {
            print("❌ VideoPreviewView: Failed to create AVPlayer")
        }
    }
}

#Preview {
    // Create a sample video URL for preview
    let sampleURL = Bundle.main.url(forResource: "sample", withExtension: "mov") ?? URL(string: "file://")!
    
    VideoPreviewView(
        videoURL: sampleURL,
        friendManager: FriendManager(authManager: AuthManager()),
        photoShareManager: PhotoShareManager(),
        storyManager: StoryManager(),
        menuAnalysisManager: MenuAnalysisManager(),
        pollManager: PollManager(),
        currentUser: UserProfile(
            id: UUID(),
            username: "testuser",
            avatarUrl: nil,
            website: nil,
            updatedAt: Date()
        )
    )
}
