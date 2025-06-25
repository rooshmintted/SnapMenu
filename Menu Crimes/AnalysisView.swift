//
//  AnalysisView.swift
//  Menu Crimes
//
//  View for displaying received media (photos and videos) from friends that haven't been opened yet
//

import SwiftUI
import AVKit

struct AnalysisView: View {
    let photoShareManager: PhotoShareManager
    let currentUser: UserProfile
    
    @State private var selectedPhoto: SharedPhoto?
    @State private var showingPhotoDetail = false
    @State private var showingMenuAnnotation = false
    
    // Menu annotation manager for analyzing menu margins
    @State private var menuAnnotationManager = MenuAnnotationManager()
    
    var body: some View {
        NavigationView {
            Group {
                if photoShareManager.unviewedPhotos.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("All Caught Up!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("No new media to analyze. When friends send you menu photos or videos, they'll appear here.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // Media grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(photoShareManager.unviewedPhotos) { photo in
                                MediaThumbnailView(
                                    media: photo,
                                    onTap: {
                                        selectedPhoto = photo
                                        showingPhotoDetail = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingMenuAnnotation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text("Menu Analysis")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if photoShareManager.unviewedCount > 0 {
                        Text("\(photoShareManager.unviewedCount) new")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .onAppear {
            print("📸 AnalysisView: Loading received media")
            Task {
                await photoShareManager.loadReceivedPhotos(for: currentUser)
            }
        }
        .sheet(isPresented: $showingPhotoDetail) {
            if let photo = selectedPhoto {
                MediaDetailView(
                    media: photo,
                    photoShareManager: photoShareManager
                )
            }
        }
        .sheet(isPresented: $showingMenuAnnotation) {
            MenuAnnotationView(annotationManager: menuAnnotationManager)
        }
    }
}

// MARK: - Media Thumbnail View
struct MediaThumbnailView: View {
    let media: SharedPhoto
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Media preview
            ZStack {
                if media.isVideo {
                    // Video thumbnail with play icon
                    AsyncImage(url: URL(string: media.mediaUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                VStack {
                                    ProgressView()
                                    Text("Loading video...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(12)
                    
                    // Video overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            // Play button overlay
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 40, height: 40)
                                )
                            
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            
                            // Video duration if available
                            if let duration = media.durationSeconds {
                                Text(formatDuration(Double(duration)))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(4)
                                    .padding(.trailing, 8)
                                    .padding(.bottom, 8)
                            }
                        }
                        
                        Spacer()
                    }
                } else {
                    // Photo thumbnail
                    AsyncImage(url: URL(string: media.mediaUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                            )
                    }
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(12)
                }
                
                // Unviewed indicator
                if !media.isViewed {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            
            // Media info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HStack(spacing: 4) {
                        // Media type icon
                        Image(systemName: media.isVideo ? "video.fill" : "photo.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        
                        Text("From \(media.sender?.username ?? "Unknown")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(timeAgoString(from: media.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let caption = media.caption, !caption.isEmpty {
                    Text("\"\(caption)\"")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}

// MARK: - Media Detail View
struct MediaDetailView: View {
    let media: SharedPhoto
    let photoShareManager: PhotoShareManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var hasMarkedAsViewed = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Media content
                if media.isVideo {
                    // Video player
                    VideoPlayer(player: AVPlayer(url: URL(string: media.mediaUrl)!))
                        .aspectRatio(contentMode: .fit)
                } else {
                    // Photo
                    AsyncImage(url: URL(string: media.mediaUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                            .foregroundColor(.white)
                    }
                }
                
                // Media info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: media.isVideo ? "video.fill" : "photo.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("From \(media.sender?.username ?? "Unknown")")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text(DateFormatter.shortDateTime.string(from: media.createdAt))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let caption = media.caption, !caption.isEmpty {
                        Text("\"\(caption)\"")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Analyze") {
                    print("📸 MediaDetailView: Analyze button tapped for \(media.isVideo ? "video" : "photo") - TODO: Add AI analysis")
                    // TODO: Implement AI analysis of the menu media
                }
                .foregroundColor(.white)
            }
        }
        .onAppear {
            // Mark media as viewed when it's opened
            if !media.isViewed && !hasMarkedAsViewed {
                hasMarkedAsViewed = true
                Task {
                    await photoShareManager.markPhotoAsViewed(media)
                }
            }
        }
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
