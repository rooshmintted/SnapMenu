//
//  StoryManager.swift
//  Menu Crimes
//
//  Manages user stories - posting, viewing, and expiration
//

import SwiftUI
import Supabase
import AVFoundation

@Observable
final class StoryManager {
    private let supabaseClient = supabase
    private let authManager: AuthManager?
    
    // Published properties for UI reactivity
    var userStories: [Story] = [] // Current user's stories
    var friendStories: [String: [Story]] = [:] // Friend stories grouped by user ID
    var allFriendStories: [Story] = [] // All friend stories in chronological order
    var isLoading = false
    var error: String?
    
    // Story upload state
    var uploadState: StoryUploadState = .idle
    
    init(authManager: AuthManager? = nil) {
        self.authManager = authManager
        print("📱 StoryManager: Initialized with auth manager: \(authManager != nil)")
    }
    
    // MARK: - Load Stories
    
    /// Load current user's active stories
    func loadUserStories(for userId: UUID) async {
        print("📱 StoryManager: Loading stories for user \(userId)")
        isLoading = true
        error = nil
        
        do {
            let response: [Story] = try await supabase
                .from("stories")
                .select("""
                    id, user_id, media_url, media_type, duration_seconds, 
                    caption, created_at, expires_at
                """)
                .eq("user_id", value: userId)
                .gt("expires_at", value: Date().ISO8601Format())
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.userStories = response
                print("📱 StoryManager: Loaded \(response.count) user stories")
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load stories: \(error.localizedDescription)"
                print("📱 StoryManager Error loading user stories: \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    /// Load stories from friends
    func loadFriendStories(for friends: [UserProfile]) async {
        print("📱 StoryManager: Loading stories for \(friends.count) friends")
        isLoading = true
        error = nil
        
        guard !friends.isEmpty else {
            await MainActor.run {
                self.friendStories = [:]
                self.allFriendStories = []
                self.isLoading = false
            }
            return
        }
        
        do {
            let friendIds = friends.map { $0.id }
            let response: [Story] = try await supabase
                .from("stories")
                .select("""
                    id, user_id, media_url, media_type, duration_seconds,
                    caption, created_at, expires_at
                """)
                .in("user_id", values: friendIds)
                .gt("expires_at", value: Date().ISO8601Format())
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                // Group stories by user ID
                var groupedStories: [String: [Story]] = [:]
                for story in response {
                    let userIdString = story.userId.uuidString
                    if groupedStories[userIdString] == nil {
                        groupedStories[userIdString] = []
                    }
                    // Add user profile to story
                    var storyWithUser = story
                    storyWithUser.user = friends.first { $0.id == story.userId }
                    groupedStories[userIdString]?.append(storyWithUser)
                }
                
                self.friendStories = groupedStories
                self.allFriendStories = response.compactMap { story in
                    var storyWithUser = story
                    storyWithUser.user = friends.first { $0.id == story.userId }
                    return storyWithUser
                }
                
                print("📱 StoryManager: Loaded \(response.count) friend stories from \(groupedStories.count) users")
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load friend stories: \(error.localizedDescription)"
                print("📱 StoryManager Error loading friend stories: \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Story Upload
    
    /// Upload photo story
    func uploadPhotoStory(image: UIImage, caption: String?, currentUser: UserProfile) async {
        await uploadStory(image: image, videoURL: nil, caption: caption, currentUser: currentUser)
    }
    
    /// Upload video story
    func uploadVideoStory(videoURL: URL, caption: String?, currentUser: UserProfile) async {
        await uploadStory(image: nil, videoURL: videoURL, caption: caption, currentUser: currentUser)
    }
    
    /// Internal upload function that handles both photos and videos
    private func uploadStory(image: UIImage?, videoURL: URL?, caption: String?, currentUser: UserProfile) async {
        guard image != nil || videoURL != nil else {
            await MainActor.run {
                self.uploadState = .error("No media provided")
            }
            return
        }
        
        await MainActor.run {
            self.uploadState = .uploading
            self.error = nil
        }
        
        do {
            let session = try await supabase.auth.session
            print("📱 StoryManager: Current user session: \(session.user.id)")
            print("📱 StoryManager: Current user from param: \(currentUser.id)")

            let mediaType: MediaType = image != nil ? .photo : .video
            let fileName = "story_\(UUID().uuidString).\(mediaType == .photo ? "jpg" : "mp4")"
            let filePath = "\(currentUser.id.uuidString)/\(fileName)"
            
            print("📱 StoryManager: Uploading \(mediaType.displayName.lowercased()) story to \(filePath)")
            
            // Upload media to Supabase Storage
            var mediaData: Data
            var duration: Int? = nil
            
            if let image = image {
                // Convert image to JPEG data
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw StoryError.imageConversionFailed
                }
                mediaData = imageData
            } else if let videoURL = videoURL {
                // Get video data and duration
                mediaData = try Data(contentsOf: videoURL)
                
                // Extract video duration
                let asset = AVAsset(url: videoURL)
                let durationTime = try await asset.load(.duration)
                duration = Int(durationTime.seconds)
                
                print("📱 StoryManager: Video duration: \(duration ?? 0) seconds")
            } else {
                throw StoryError.noMediaProvided
            }
            
            // Upload to storage
            try await supabase.storage
                .from("stories")
                .upload(
                    path: filePath,
                    file: mediaData,
                    options: FileOptions(
                        cacheControl: "3600",
                        upsert: false
                    )
                )
            
            // Get public URL
            let mediaURL = try supabase.storage
                .from("stories")
                .getPublicURL(path: filePath)
            
            print("📱 StoryManager: Media uploaded successfully: \(mediaURL)")
            
            // Create story record in database
            let newStory = NewStoryData(
                userId: currentUser.id,
                mediaUrl: mediaURL.absoluteString,
                mediaType: mediaType,
                durationSeconds: duration,
                caption: caption
            )
            
            let _: Story = try await supabase
                .from("stories")
                .insert(newStory)
                .select()
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.uploadState = .success
                print("📱 StoryManager: Story uploaded successfully")
            }
            
            // Reload user stories to include the new one
            await loadUserStories(for: currentUser.id)
            
        } catch {
            await MainActor.run {
                let errorMessage = "Failed to upload story: \(error.localizedDescription)"
                self.uploadState = .error(errorMessage)
                self.error = errorMessage
                print("📱 StoryManager Error uploading story: \(error)")
            }
        }
    }
    
    // MARK: - Story Queries
    
    /// Check if a user has active stories
    func hasStories(for userId: UUID) -> Bool {
        let userIdString = userId.uuidString
        if let userStories = friendStories[userIdString] {
            // Filter out expired stories
            let activeStories = userStories.filter { !$0.isExpired }
            return !activeStories.isEmpty
        }
        return false
    }
    
    /// Get active stories for a specific user
    func getStories(for userId: UUID) -> [Story] {
        let userIdString = userId.uuidString
        if let userStories = friendStories[userIdString] {
            // Return only non-expired stories, sorted by creation date
            let activeStories = userStories
                .filter { !$0.isExpired }
                .sorted { $0.createdAt > $1.createdAt }
            
            // Preload media URLs to ensure they're accessible
            return activeStories.map { story in
                let updatedUrl = constructPublicURL(for: story.mediaUrl, userId: story.userId)
                print("📱 StoryManager: Preloaded story URL - \(updatedUrl)")
                
                // Return story with updated URL - we'll handle URL construction at display time instead
                // Since we can't easily create a new Story instance due to the var user property
                return story
            }
        }
        return []
    }
    
    /// Preload stories for a specific friend in the background
    func preloadStoriesForFriend(_ friend: UserProfile) async {
        print("⏳ StoryManager: Preloading stories for \(friend.username)")
        
        // Check if we already have recent stories for this user
        let userIdString = friend.id.uuidString
        if let existingStories = friendStories[userIdString], !existingStories.isEmpty {
            print("✅ StoryManager: Stories already loaded for \(friend.username)")
            return
        }
        
        // Load stories for this specific friend
        do {
            let response: [Story] = try await supabase
                .from("stories")
                .select("""
                    id, user_id, media_url, media_type, duration_seconds,
                    caption, created_at, expires_at
                """)
                .eq("user_id", value: friend.id)
                .gt("expires_at", value: Date().ISO8601Format())
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                // Add user profile to stories and store them
                let storiesWithUser = response.map { story in
                    var storyWithUser = story
                    storyWithUser.user = friend
                    return storyWithUser
                }
                
                self.friendStories[userIdString] = storiesWithUser
                print("✅ StoryManager: Preloaded \(response.count) stories for \(friend.username)")
            }
            
        } catch {
            print("❌ StoryManager: Failed to preload stories for \(friend.username): \(error)")
        }
    }
    
    /// Construct proper public URL for story media
    private func constructPublicURL(for mediaUrl: String, userId: UUID) -> String {
        // If it's already a full URL, return as is (URLs from database are already public URLs)
        if mediaUrl.hasPrefix("http") {
            print("🔗 StoryManager: Using existing public URL: \(mediaUrl)")
            return mediaUrl
        }
        
        // If it's a relative path, construct public URL from storage
        // This handles the case where we might have just stored the path
        // Expected path format: {userId}/story_{uuid}.{extension}
        print("🔗 StoryManager: Constructing public URL for path: \(mediaUrl)")
        
        do {
            let publicURL = try supabase.storage
                .from("stories")
                .getPublicURL(path: mediaUrl)
            print("🔗 StoryManager: Constructed public URL: \(publicURL)")
            return publicURL.absoluteString
        } catch {
            print("❌ StoryManager: Failed to construct public URL for \(mediaUrl): \(error)")
            // If construction fails, try to build the expected Supabase public URL format
            let supabaseUrl = "https://bepoadtvabwmjxlmlecv.supabase.co/storage/v1/object/public/stories/\(mediaUrl)"
            print("🔗 StoryManager: Fallback URL: \(supabaseUrl)")
            return supabaseUrl
        }
    }
    
    /// Get username for a user ID (helper for story viewing)
    func getUsername(for userId: UUID) -> String {
        // This is a simplified lookup - in a real app you'd want to cache user profiles
        // or pass in the friend list to avoid repeated lookups
        return "Unknown User" // TODO: Implement proper username lookup
    }
    
    // MARK: - Story Management
    
    /// Get current user ID for ownership checks
    func getCurrentUserId() -> UUID? {
        print("🔐 StoryManager: Getting current user ID for ownership check")
        return authManager?.authState.currentUser?.id
    }
    
    /// Delete a story from the database and storage
    func deleteStory(_ story: Story) async {
        print("🗑️ StoryManager: Starting deletion of story \(story.id)")
        
        do {
            // Delete from database
            let response = try await supabase.database
                .from("stories")
                .delete()
                .eq("id", value: story.id)
                .execute()
            
            print("✅ StoryManager: Successfully deleted story \(story.id) from database")
            
            // Delete from storage
            let fileName = URL(string: story.mediaUrl)?.lastPathComponent ?? ""
            if !fileName.isEmpty {
                // Extract the full path from the URL - it should be in format userId/fileName
                let pathComponents = URL(string: story.mediaUrl)?.pathComponents ?? []
                let filePath = pathComponents.suffix(2).joined(separator: "/") // Get last 2 components: userId/fileName
                
                try await supabase.storage
                    .from("stories")
                    .remove(paths: [filePath])
                
                print("✅ StoryManager: Successfully deleted story media file: \(filePath)")
            }
            
            // Update local state
            await MainActor.run {
                userStories.removeAll { $0.id == story.id }
                
                // Also remove from friend stories if present
                for (username, stories) in friendStories {
                    let filteredStories = stories.filter { $0.id != story.id }
                    if filteredStories.count != stories.count {
                        friendStories[username] = filteredStories
                    }
                }
                
                print("✅ StoryManager: Updated local story state after deletion")
            }
            
        } catch {
            print("❌ StoryManager: Failed to delete story \(story.id): \(error)")
            await MainActor.run {
                self.error = "Failed to delete story: \(error.localizedDescription)"
            }
        }
    }
    
    /// Reset upload state
    func resetUploadState() {
        uploadState = .idle
        error = nil
    }
    
    /// Get stories for a specific user
    func getStoriesForUser(_ userId: UUID) -> [Story] {
        return friendStories[userId.uuidString] ?? []
    }
    
    /// Check if user has active stories
    func userHasActiveStories(_ userId: UUID) -> Bool {
        let stories = friendStories[userId.uuidString] ?? []
        return !stories.isEmpty
    }
    
    /// Get public URL for story media (public method for use in views)
    func getPublicURL(for story: Story) -> String {
        return constructPublicURL(for: story.mediaUrl, userId: story.userId)
    }
}

// MARK: - Supporting Types

enum StoryUploadState: Equatable {
    case idle
    case uploading
    case success
    case error(String)
}

enum StoryError: LocalizedError {
    case imageConversionFailed
    case noMediaProvided
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image"
        case .noMediaProvided:
            return "No image or video provided"
        case .uploadFailed:
            return "Failed to upload story"
        }
    }
}

struct NewStoryData: Codable {
    let userId: UUID
    let mediaUrl: String
    let mediaType: MediaType
    let durationSeconds: Int?
    let caption: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case durationSeconds = "duration_seconds"
        case caption
    }
}
