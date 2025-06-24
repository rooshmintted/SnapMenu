//
//  FriendSelectionView.swift
//  Menu Crimes
//
//  View for selecting a friend to send media (photo or video) to
//

import SwiftUI
import AVKit

struct FriendSelectionView: View {
    // Media parameters - either image or videoURL should be provided
    let image: UIImage?
    let videoURL: URL?
    let friendManager: FriendManager
    let photoShareManager: PhotoShareManager
    let storyManager: StoryManager
    let currentUser: UserProfile
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriends: Set<UserProfile> = []
    @State private var caption: String = ""
    @State private var showingCaptionInput = false
    @State private var showingAddToStoryInput = false
    @State private var storyCaption: String = ""
    
    // Computed property to determine media type
    private var isVideo: Bool {
        videoURL != nil
    }
    
    private var mediaTitle: String {
        isVideo ? "Send Video" : "Send Photo"
    }
    
    // Computed property for button text based on selection count
    private var sendButtonText: String {
        let count = selectedFriends.count
        if count == 0 {
            return "Select Friend(s)"
        } else if count == 1 {
            return "Send to 1 Friend"
        } else {
            return "Send to \(count) Friends"
        }
    }
    
    // Convenience initializers for backward compatibility
    init(image: UIImage, friendManager: FriendManager, photoShareManager: PhotoShareManager, storyManager: StoryManager, currentUser: UserProfile) {
        self.image = image
        self.videoURL = nil
        self.friendManager = friendManager
        self.photoShareManager = photoShareManager
        self.storyManager = storyManager
        self.currentUser = currentUser
    }
    
    init(videoURL: URL, friendManager: FriendManager, photoShareManager: PhotoShareManager, storyManager: StoryManager, currentUser: UserProfile) {
        self.image = nil
        self.videoURL = videoURL
        self.friendManager = friendManager
        self.photoShareManager = photoShareManager
        self.storyManager = storyManager
        self.currentUser = currentUser
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Media preview at top
                HStack {
                    if let image = image {
                        // Photo preview
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)
                    } else if let videoURL = videoURL {
                        // Video preview thumbnail
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)
                            .disabled(true) // Disable interaction in preview
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mediaTitle)
                            .font(.headline)
                        
                        if !caption.isEmpty {
                            Text("\"\(caption)\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Add Caption") {
                        showingCaptionInput = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Friends list
                if friendManager.friends.isEmpty {
                    // No friends state
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Friends Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add friends to start sharing menu photos with them.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    List(friendManager.friends, id: \.id) { friend in
                        FriendRowView(
                            friend: friend,
                            isSelected: selectedFriends.contains(friend),
                            onSelect: {
                                // Toggle friend selection
                                if selectedFriends.contains(friend) {
                                    selectedFriends.remove(friend)
                                    print("📸 FriendSelectionView: Deselected \(friend.username)")
                                } else {
                                    selectedFriends.insert(friend)
                                    print("📸 FriendSelectionView: Selected \(friend.username)")
                                }
                                print("📸 FriendSelectionView: Total selected: \(selectedFriends.count)")
                            }
                        )
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Send button
                if !selectedFriends.isEmpty {
                    VStack(spacing: 12) {
                        if case .uploading = photoShareManager.shareState {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Uploading...")
                                    .font(.caption)
                            }
                        } else if case .sending = photoShareManager.shareState {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Sending to \(selectedFriends.count) friend\(selectedFriends.count == 1 ? "" : "s")...")
                                    .font(.caption)
                            }
                        } else {
                            Button(action: sendToSelectedFriends) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text(sendButtonText)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(photoShareManager.shareState == .uploading || photoShareManager.shareState == .sending)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
                }
                
                // Add to Story button
                Button(action: addToStory) {
                    HStack {
                        if case .uploading = storyManager.uploadState {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                            Text("Adding to Story...")
                                .fontWeight(.semibold)
                        } else {
                            Image(systemName: "camera.fill")
                            Text("Add to Story")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(storyManager.uploadState == .uploading)
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
            }
            .navigationTitle(mediaTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            print("📸 FriendSelectionView: Loading friends")
            Task {
                await friendManager.loadFriends()
            }
        }
        .onChange(of: photoShareManager.shareState) { _, newState in
            if case .success = newState {
                print("📸 FriendSelectionView: \(isVideo ? "Video" : "Photo") sent successfully to \(selectedFriends.count) friend(s), dismissing view")
                dismiss()
            }
        }
        .onChange(of: storyManager.uploadState) { _, newState in
            if case .success = newState {
                print("📸 FriendSelectionView: \(isVideo ? "Video" : "Photo") story uploaded successfully, dismissing view")
                dismiss()
            }
        }
        .alert("Caption", isPresented: $showingCaptionInput) {
            TextField("Add a caption...", text: $caption)
            Button("Cancel", role: .cancel) { }
            Button("Done") { }
        } message: {
            Text("Add an optional message with your \(isVideo ? "video" : "photo")")
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: {
                if case .error = photoShareManager.shareState { return true } else { return false }
            },
            set: { _ in }
        )) {
            Button("OK") {
                photoShareManager.resetShareState()
            }
        } message: {
            if case .error(let message) = photoShareManager.shareState {
                Text(message)
            }
        }
        .alert("Add to Story", isPresented: $showingAddToStoryInput) {
            TextField("Add a caption...", text: $storyCaption)
            Button("Cancel", role: .cancel) { }
            Button("Done") { uploadToStory() }
        } message: {
            Text("Add an optional message with your \(isVideo ? "video" : "photo") story")
        }
    }
    
    // Updated send function to handle multiple friends
    private func sendToSelectedFriends() {
        guard !selectedFriends.isEmpty else { 
            print("📸 FriendSelectionView: No friends selected")
            return 
        }
        
        let friendNames = selectedFriends.compactMap { $0.username }.joined(separator: ", ")
        print("📸 FriendSelectionView: Sending \(isVideo ? "video" : "photo") to \(selectedFriends.count) friend(s): \(friendNames)")
        
        Task {
            if let image = image {
                // Send photo to multiple friends
                await photoShareManager.sendPhotoToMultipleFriends(
                    image: image,
                    friends: Array(selectedFriends),
                    caption: caption.isEmpty ? nil : caption,
                    currentUser: currentUser
                )
            } else if let videoURL = videoURL {
                // Send video to multiple friends
                await photoShareManager.sendVideoToMultipleFriends(
                    videoURL: videoURL,
                    friends: Array(selectedFriends),
                    caption: caption.isEmpty ? nil : caption,
                    currentUser: currentUser
                )
            }
        }
    }
    
    private func addToStory() {
        print("📸 FriendSelectionView: Adding to story")
        showingAddToStoryInput = true
    }
    
    private func uploadToStory() {
        print("📸 FriendSelectionView: Uploading to story")
        
        Task {
            if let image = image {
                // Add photo to story
                await storyManager.uploadPhotoStory(
                    image: image,
                    caption: storyCaption.isEmpty ? nil : storyCaption,
                    currentUser: currentUser
                )
            } else if let videoURL = videoURL {
                // Add video to story
                await storyManager.uploadVideoStory(
                    videoURL: videoURL,
                    caption: storyCaption.isEmpty ? nil : storyCaption,
                    currentUser: currentUser
                )
            }
        }
    }
}

// MARK: - Friend Row View
struct FriendRowView: View {
    let friend: UserProfile
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            // Profile image placeholder
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(friend.username.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.username)
                    .font(.headline)
                
                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            } else {
                Circle()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
