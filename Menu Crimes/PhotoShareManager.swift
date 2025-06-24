//
//  PhotoShareManager.swift
//  Menu Crimes
//
//  Manages photo sharing between friends - uploading, sending, and viewing shared photos
//

import Foundation
import SwiftUI
import Supabase
import AVFoundation

@Observable
final class PhotoShareManager {
    
    private let supabaseClient = supabase
    
    var shareState: PhotoShareState = .idle
    var receivedPhotos: [SharedPhoto] = []
    var sentPhotos: [SharedPhoto] = []
    var unviewedCount: Int = 0
    
    init() {
        print("📸 PhotoShareManager: Initialized")
    }
    
    // MARK: - Photo Sharing Functions
    
    /// Upload image to Supabase Storage and send to friend
    func sendPhotoToFriend(image: UIImage, friend: UserProfile, caption: String? = nil, currentUser: UserProfile) async {
        print("📸 PhotoShareManager: Starting photo send to \(friend.username)")
        shareState = .uploading
        
        do {
            // Upload image to Supabase Storage
            let mediaUrl = try await uploadImage(image: image, currentUser: currentUser)
            print("📸 PhotoShareManager: Image uploaded successfully to \(mediaUrl)")
            
            shareState = .sending
            
            // Create shared photo record
            let sharedPhoto = SharedPhoto(
                id: UUID(),
                senderId: currentUser.id,
                receiverId: friend.id,
                mediaUrl: mediaUrl,
                mediaType: .photo,
                durationSeconds: nil,
                caption: caption,
                isViewed: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Insert into database
            try await supabaseClient
                .from("shared_photos")
                .insert(sharedPhoto)
                .execute()
            
            print("📸 PhotoShareManager: Photo sent successfully")
            shareState = .success
            
            // Add to sent photos list
            var photoWithSender = sharedPhoto
            photoWithSender.sender = currentUser
            photoWithSender.receiver = friend
            sentPhotos.append(photoWithSender)
            
        } catch {
            print("❌ PhotoShareManager: Error sending photo: \(error)")
            shareState = .error("Failed to send photo: \(error.localizedDescription)")
        }
    }
    
    /// Upload video to Supabase Storage and send to friend
    func sendVideoToFriend(videoURL: URL, friend: UserProfile, caption: String? = nil, currentUser: UserProfile) async {
        print("🎬 PhotoShareManager: Starting video send to \(friend.username)")
        shareState = .uploading
        
        do {
            // Get video duration
            let duration = try await getVideoDuration(from: videoURL)
            print("🎬 PhotoShareManager: Video duration: \(duration) seconds")
            
            // Upload video to Supabase Storage
            let mediaUrl = try await uploadVideo(videoURL: videoURL, currentUser: currentUser)
            print("🎬 PhotoShareManager: Video uploaded successfully to \(mediaUrl)")
            
            shareState = .sending
            
            // Create shared video record
            let sharedVideo = SharedPhoto(
                id: UUID(),
                senderId: currentUser.id,
                receiverId: friend.id,
                mediaUrl: mediaUrl,
                mediaType: .video,
                durationSeconds: Int(duration),
                caption: caption,
                isViewed: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Insert into database
            try await supabaseClient
                .from("shared_photos")
                .insert(sharedVideo)
                .execute()
            
            print("🎬 PhotoShareManager: Video sent successfully")
            shareState = .success
            
            // Add to sent photos list
            var videoWithSender = sharedVideo
            videoWithSender.sender = currentUser
            videoWithSender.receiver = friend
            sentPhotos.append(videoWithSender)
            
        } catch {
            print("❌ PhotoShareManager: Error sending video: \(error)")
            shareState = .error("Failed to send video: \(error.localizedDescription)")
        }
    }

    // MARK: - Multiple Friend Sharing Functions
    
    /// Upload image and send to multiple friends
    func sendPhotoToMultipleFriends(image: UIImage, friends: [UserProfile], caption: String? = nil, currentUser: UserProfile) async {
        let friendNames = friends.map { $0.username }.joined(separator: ", ")
        print("📸 PhotoShareManager: Starting photo send to \(friends.count) friends: \(friendNames)")
        shareState = .uploading
        
        do {
            // Upload image once to Supabase Storage
            let mediaUrl = try await uploadImage(image: image, currentUser: currentUser)
            print("📸 PhotoShareManager: Image uploaded successfully to \(mediaUrl)")
            
            shareState = .sending
            
            // Create shared photo records for each friend
            var sharedPhotos: [SharedPhoto] = []
            for friend in friends {
                let sharedPhoto = SharedPhoto(
                    id: UUID(),
                    senderId: currentUser.id,
                    receiverId: friend.id,
                    mediaUrl: mediaUrl,
                    mediaType: .photo,
                    durationSeconds: nil,
                    caption: caption,
                    isViewed: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                sharedPhotos.append(sharedPhoto)
            }
            
            // Insert all records into database
            try await supabaseClient
                .from("shared_photos")
                .insert(sharedPhotos)
                .execute()
            
            print("📸 PhotoShareManager: Photo sent successfully to \(friends.count) friends")
            shareState = .success
            
            // Add to sent photos list with sender/receiver info
            for (index, sharedPhoto) in sharedPhotos.enumerated() {
                var photoWithInfo = sharedPhoto
                photoWithInfo.sender = currentUser
                photoWithInfo.receiver = friends[index]
                sentPhotos.append(photoWithInfo)
            }
            
        } catch {
            print("❌ PhotoShareManager: Error sending photo to multiple friends: \(error)")
            shareState = .error("Failed to send photo: \(error.localizedDescription)")
        }
    }
    
    /// Upload video and send to multiple friends
    func sendVideoToMultipleFriends(videoURL: URL, friends: [UserProfile], caption: String? = nil, currentUser: UserProfile) async {
        let friendNames = friends.map { $0.username }.joined(separator: ", ")
        print("🎬 PhotoShareManager: Starting video send to \(friends.count) friends: \(friendNames)")
        shareState = .uploading
        
        do {
            // Get video duration
            let duration = try await getVideoDuration(from: videoURL)
            print("🎬 PhotoShareManager: Video duration: \(duration) seconds")
            
            // Upload video once to Supabase Storage
            let mediaUrl = try await uploadVideo(videoURL: videoURL, currentUser: currentUser)
            print("🎬 PhotoShareManager: Video uploaded successfully to \(mediaUrl)")
            
            shareState = .sending
            
            // Create shared video records for each friend
            var sharedVideos: [SharedPhoto] = []
            for friend in friends {
                let sharedVideo = SharedPhoto(
                    id: UUID(),
                    senderId: currentUser.id,
                    receiverId: friend.id,
                    mediaUrl: mediaUrl,
                    mediaType: .video,
                    durationSeconds: Int(duration),
                    caption: caption,
                    isViewed: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                sharedVideos.append(sharedVideo)
            }
            
            // Insert all records into database
            try await supabaseClient
                .from("shared_photos")
                .insert(sharedVideos)
                .execute()
            
            print("🎬 PhotoShareManager: Video sent successfully to \(friends.count) friends")
            shareState = .success
            
            // Add to sent photos list with sender/receiver info
            for (index, sharedVideo) in sharedVideos.enumerated() {
                var videoWithInfo = sharedVideo
                videoWithInfo.sender = currentUser
                videoWithInfo.receiver = friends[index]
                sentPhotos.append(videoWithInfo)
            }
            
        } catch {
            print("❌ PhotoShareManager: Error sending video to multiple friends: \(error)")
            shareState = .error("Failed to send video: \(error.localizedDescription)")
        }
    }

    /// Upload image to Supabase Storage
    private func uploadImage(image: UIImage, currentUser: UserProfile) async throws -> String {
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "PhotoShareManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Generate unique filename
        let filename = "photos/\(UUID().uuidString).jpg"
        
        print("📸 PhotoShareManager: Uploading to bucket 'menu-crimes-photos' with filename: \(filename)")
        
        // Upload to Supabase Storage (new public bucket)
        try await supabaseClient.storage
            .from("menu-crimes-photos")
            .upload(path: filename, file: imageData, options: FileOptions(contentType: "image/jpeg"))
        
        // Get public URL
        let publicURL = try supabaseClient.storage
            .from("menu-crimes-photos")
            .getPublicURL(path: filename)
        
        return publicURL.absoluteString
    }
    
    /// Upload video to Supabase Storage (converts to MP4 format)
    private func uploadVideo(videoURL: URL, currentUser: UserProfile) async throws -> String {
        print("🎬 PhotoShareManager: Converting video from MOV to MP4 format...")
        
        // Convert video to MP4 format
        let mp4URL = try await convertVideoToMP4(inputURL: videoURL)
        
        // Read converted video data
        let videoData = try Data(contentsOf: mp4URL)
        print("🎬 PhotoShareManager: Converted video data size: \(videoData.count) bytes")
        
        // Generate unique filename with MP4 extension
        let filename = "videos/\(UUID().uuidString).mp4"
        
        print("🎬 PhotoShareManager: Uploading to bucket 'menu-crimes-photos' with filename: \(filename)")
        
        // Upload to Supabase Storage
        _ = try await supabaseClient.storage
            .from("menu-crimes-photos")
            .upload(path: filename, file: videoData, options: FileOptions(contentType: "video/mp4"))
        
        // Get public URL
        let publicURL = try supabaseClient.storage
            .from("menu-crimes-photos")
            .getPublicURL(path: filename)
        
        // Clean up temporary MP4 file
        try? FileManager.default.removeItem(at: mp4URL)
        
        return publicURL.absoluteString
    }
    
    /// Convert video from MOV to MP4 format using AVAssetExportSession
    private func convertVideoToMP4(inputURL: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            // Create output URL for MP4 file
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
            
            // Create AVAsset from input URL
            let asset = AVAsset(url: inputURL)
            
            // Create export session
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
                continuation.resume(throwing: NSError(domain: "VideoConversion", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]))
                return
            }
            
            // Configure export session
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            print("🎬 PhotoShareManager: Starting video conversion to MP4...")
            
            // Start export
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("🎬 PhotoShareManager: Video conversion completed successfully")
                    continuation.resume(returning: outputURL)
                case .failed:
                    let error = exportSession.error ?? NSError(domain: "VideoConversion", code: 2, userInfo: [NSLocalizedDescriptionKey: "Export failed"])
                    print("❌ PhotoShareManager: Video conversion failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                case .cancelled:
                    print("❌ PhotoShareManager: Video conversion was cancelled")
                    continuation.resume(throwing: NSError(domain: "VideoConversion", code: 3, userInfo: [NSLocalizedDescriptionKey: "Export was cancelled"]))
                default:
                    print("❌ PhotoShareManager: Video conversion ended with unknown status: \(exportSession.status.rawValue)")
                    continuation.resume(throwing: NSError(domain: "VideoConversion", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown export status"]))
                }
            }
        }
    }
    
    /// Get video duration using AVAsset
    private func getVideoDuration(from url: URL) async throws -> Double {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }

    // MARK: - Loading Functions
    
    /// Load photos received by current user
    func loadReceivedPhotos(for currentUser: UserProfile) async {
        print("📸 PhotoShareManager: Loading received photos for user \(currentUser.id)")
        
        do {
            let response: [SharedPhoto] = try await supabaseClient
                .from("shared_photos")
                .select("""
                    *,
                    sender:profiles!sender_id(id, username, full_name, avatar_url),
                    receiver:profiles!receiver_id(id, username, full_name, avatar_url)
                """)
                .eq("receiver_id", value: currentUser.id)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            receivedPhotos = response
            unviewedCount = receivedPhotos.filter { !$0.isViewed }.count
            
            print("📸 PhotoShareManager: Loaded \(receivedPhotos.count) received photos, \(unviewedCount) unviewed")
            
        } catch {
            print("❌ PhotoShareManager: Error loading received photos: \(error)")
        }
    }
    
    /// Load photos sent by current user
    func loadSentPhotos(for currentUser: UserProfile) async {
        print("📸 PhotoShareManager: Loading sent photos for user \(currentUser.id)")
        
        do {
            let response: [SharedPhoto] = try await supabaseClient
                .from("shared_photos")
                .select("""
                    *,
                    sender:profiles!sender_id(id, username, full_name, avatar_url),
                    receiver:profiles!receiver_id(id, username, full_name, avatar_url)
                """)
                .eq("sender_id", value: currentUser.id)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            sentPhotos = response
            
            print("📸 PhotoShareManager: Loaded \(sentPhotos.count) sent photos")
            
        } catch {
            print("❌ PhotoShareManager: Error loading sent photos: \(error)")
        }
    }
    
    /// Mark photo as viewed
    func markPhotoAsViewed(_ photo: SharedPhoto) async {
        print("📸 PhotoShareManager: Marking photo \(photo.id) as viewed")
        
        do {
            try await supabaseClient
                .from("shared_photos")
                .update(["is_viewed": true])
                .eq("id", value: photo.id)
                .execute()
            
            // Update local state
            if let index = receivedPhotos.firstIndex(where: { $0.id == photo.id }) {
                var updatedPhoto = receivedPhotos[index]
                updatedPhoto = SharedPhoto(
                    id: updatedPhoto.id,
                    senderId: updatedPhoto.senderId,
                    receiverId: updatedPhoto.receiverId,
                    mediaUrl: updatedPhoto.mediaUrl,
                    mediaType: updatedPhoto.mediaType,
                    durationSeconds: updatedPhoto.durationSeconds,
                    caption: updatedPhoto.caption,
                    isViewed: true,
                    createdAt: updatedPhoto.createdAt,
                    updatedAt: Date(),
                    sender: updatedPhoto.sender,
                    receiver: updatedPhoto.receiver
                )
                receivedPhotos[index] = updatedPhoto
                unviewedCount = receivedPhotos.filter { !$0.isViewed }.count
            }
            
        } catch {
            print("❌ PhotoShareManager: Error marking photo as viewed: \(error)")
        }
    }
    
    /// Reset share state
    func resetShareState() {
        shareState = .idle
    }
    
    /// Computed property for unviewed photos only
    var unviewedPhotos: [SharedPhoto] {
        return receivedPhotos.filter { !$0.isViewed }
    }
}
