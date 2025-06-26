//
//  Models.swift
//  Menu Crimes
//
//  Data models for user authentication and friend system
//

import Foundation
import Supabase

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let username: String  // Made non-optional as primary display name
    let avatarUrl: String?
    let website: String?   // Exists in your database schema
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarUrl = "avatar_url"
        case website
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
    
    // Hashable conformance - hash based on unique ID
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Friend Request Model
struct FriendRequest: Codable, Identifiable, Equatable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let status: FriendRequestStatus
    let createdAt: Date
    let updatedAt: Date
    
    // Populated from joins
    var sender: UserProfile?
    var receiver: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: FriendRequest, rhs: FriendRequest) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Friend Request Status
enum FriendRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case blocked = "blocked"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        case .blocked: return "Blocked"
        }
    }
}

// MARK: - Friendship Model
struct Friendship: Codable, Identifiable, Equatable {
    let id: UUID
    let userId1: UUID
    let userId2: UUID
    let createdAt: Date
    
    // Populated from joins
    var friend: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId1 = "user_id1"
        case userId2 = "user_id2"
        case createdAt = "created_at"
    }
    
    static func == (lhs: Friendship, rhs: Friendship) -> Bool {
        lhs.id == rhs.id
    }
    
    // Helper to get the friend user ID
    func getFriendId(for currentUserId: UUID) -> UUID {
        return userId1 == currentUserId ? userId2 : userId1
    }
}

// MARK: - Contact Model (for contact integration)
struct ContactInfo: Identifiable, Equatable {
    let id = UUID()
    let firstName: String
    let lastName: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    static func == (lhs: ContactInfo, rhs: ContactInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Authentication State
enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated(UserProfile)
    case error(String)
    
    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
    
    var currentUser: UserProfile? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}

// MARK: - Media Type
enum MediaType: String, Codable, CaseIterable {
    case photo = "photo"
    case video = "video"
    
    var displayName: String {
        switch self {
        case .photo: return "Photo"
        case .video: return "Video"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .photo: return "photo"
        case .video: return "video"
        }
    }
}

// MARK: - Shared Media Model (formerly SharedPhoto)
struct SharedPhoto: Codable, Identifiable, Equatable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let mediaUrl: String // URL to the uploaded media in Supabase Storage (renamed from imageUrl)
    let mediaType: MediaType // Type of media: photo or video
    let durationSeconds: Int? // Duration for videos (nil for photos)
    let caption: String? // Optional message with the media
    let isViewed: Bool // Whether the recipient has viewed the media
    let createdAt: Date
    let updatedAt: Date
    
    // Populated from joins
    var sender: UserProfile?
    var receiver: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case durationSeconds = "duration_seconds"
        case caption
        case isViewed = "is_viewed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: SharedPhoto, rhs: SharedPhoto) -> Bool {
        lhs.id == rhs.id
    }
    
    // Computed properties for backward compatibility
    var imageUrl: String { mediaUrl } // For existing photo code
    var isPhoto: Bool { mediaType == .photo }
    var isVideo: Bool { mediaType == .video }
}

// MARK: - Story Model
struct Story: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let mediaUrl: String
    let mediaType: MediaType
    let durationSeconds: Int?
    let caption: String?
    let createdAt: Date
    let expiresAt: Date
    
    // Populated from joins
    var user: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case durationSeconds = "duration_seconds"
        case caption
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
    
    static func == (lhs: Story, rhs: Story) -> Bool {
        lhs.id == rhs.id
    }
    
    // Computed properties
    var isPhoto: Bool { mediaType == .photo }
    var isVideo: Bool { mediaType == .video }
    var isExpired: Bool { expiresAt < Date() }
    var isActive: Bool { !isExpired }
    
    // Time remaining until expiry
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
    
    // Formatted time remaining (e.g., "2h", "45m", "10s")
    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        if remaining <= 0 {
            return "Expired"
        }
        
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) / 60 % 60
        let seconds = Int(remaining) % 60
        
        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    
    // Custom initializer for creating stories programmatically
    init(id: UUID, userId: UUID, mediaUrl: String, mediaType: MediaType, 
         durationSeconds: Int?, caption: String?, createdAt: Date, expiresAt: Date, 
         user: UserProfile? = nil) {
        self.id = id
        self.userId = userId
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
        self.durationSeconds = durationSeconds
        self.caption = caption
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.user = user
    }
}

// MARK: - Photo Share State
enum PhotoShareState: Equatable {
    case idle
    case selecting
    case uploading
    case sending
    case success
    case error(String)
}

// MARK: - Menu Analysis Models
/// Response model for menu analysis from OpenAI
struct MenuAnalysisResponse: Codable {
    let success: Bool
    let analysis: AnalysisData
    let dishes_found: Int
}

struct AnalysisData: Codable {
    let dishes: [DishAnalysis]
    let overall_notes: String
}

struct DishAnalysis: Codable, Identifiable {
    let id = UUID()
    let dishName: String
    let marginPercentage: Int
    let justification: String
    let coordinates: DishCoordinates? // Optional since we get coordinates from Vision Framework
    let price: String
    let estimatedFoodCost: Double
    
    enum CodingKeys: String, CodingKey {
        case dishName = "dish_name"
        case marginPercentage = "margin_percentage"
        case justification, coordinates, price
        case estimatedFoodCost = "estimated_food_cost"
    }
}

struct DishCoordinates: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

enum MenuAnalysisState {
    case idle
    case uploading
    case analyzing
    case completed(MenuAnalysisResponse)
    case error(String)
}

// MARK: - Menu Poll Models
struct MenuPoll: Codable, Identifiable, Equatable {
    let id: UUID
    let creatorId: UUID
    let title: String?
    let description: String?
    let menuImageUrl: String
    let analysisData: MenuAnalysisResponse // Store the full analysis response
    let pollOptions: [String] // Array of dish names available for voting
    let expiresAt: Date
    let isActive: Bool
    let allowMultipleVotes: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // Populated from joins
    var creator: UserProfile?
    var votes: [PollVote]?
    var recipients: [PollRecipient]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case title
        case description
        case menuImageUrl = "menu_image_url"
        case analysisData = "analysis_data"
        case pollOptions = "poll_options"
        case expiresAt = "expires_at"
        case isActive = "is_active"
        case allowMultipleVotes = "allow_multiple_votes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: MenuPoll, rhs: MenuPoll) -> Bool {
        lhs.id == rhs.id
    }
    
    // Computed properties
    var isExpired: Bool { expiresAt < Date() }
    var timeRemaining: TimeInterval { max(0, expiresAt.timeIntervalSinceNow) }
    
    // Formatted time remaining (e.g., "2h", "45m", "10s")
    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        if remaining <= 0 {
            return "Expired"
        }
        
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) / 60 % 60
        let seconds = Int(remaining) % 60
        
        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

struct PollVote: Codable, Identifiable, Equatable {
    let id: UUID
    let pollId: UUID
    let voterId: UUID
    let selectedDishes: [String] // Array of dish names selected
    let voteComment: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Populated from joins
    var voter: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case pollId = "poll_id"
        case voterId = "voter_id"
        case selectedDishes = "selected_dishes"
        case voteComment = "vote_comment"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: PollVote, rhs: PollVote) -> Bool {
        lhs.id == rhs.id
    }
}

struct PollRecipient: Codable, Identifiable, Equatable {
    let id: UUID
    let pollId: UUID
    let recipientId: UUID
    let hasVoted: Bool
    let notifiedAt: Date?
    let createdAt: Date
    
    // Populated from joins
    var recipient: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case pollId = "poll_id"
        case recipientId = "recipient_id"
        case hasVoted = "has_voted"
        case notifiedAt = "notified_at"
        case createdAt = "created_at"
    }
    
    static func == (lhs: PollRecipient, rhs: PollRecipient) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Poll Configuration
struct PollConfiguration {
    var duration: PollDuration = .twentyFourHours
    var allowMultipleVotes: Bool = false
    var question: String = "Which dish would you order from this menu?"
    var description: String = ""
    
    var expiresAt: Date {
        Date().addingTimeInterval(duration.timeInterval)
    }
}

enum PollDuration: String, CaseIterable {
    case oneHour = "1h"
    case sixHours = "6h"
    case twelveHours = "12h"
    case twentyFourHours = "24h"
    case fortyEightHours = "48h"
    case oneWeek = "1w"
    
    var displayName: String {
        switch self {
        case .oneHour: return "1 Hour"
        case .sixHours: return "6 Hours"
        case .twelveHours: return "12 Hours"
        case .twentyFourHours: return "24 Hours"
        case .fortyEightHours: return "2 Days"
        case .oneWeek: return "1 Week"
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .oneHour: return 3600
        case .sixHours: return 21600
        case .twelveHours: return 43200
        case .twentyFourHours: return 86400
        case .fortyEightHours: return 172800
        case .oneWeek: return 604800
        }
    }
}

// MARK: - Poll State
enum PollState: Equatable {
    case idle
    case creating
    case success(MenuPoll)
    case error(String)
}
