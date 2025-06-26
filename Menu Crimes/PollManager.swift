//
//  PollManager.swift
//  Menu Crimes
//
//  Created by Roosh on 6/25/25.
//

import Foundation
import Supabase

// MARK: - Database Insert Models
struct PollInsert: Codable {
    let id: String
    let creator_id: String
    let title: String?
    let description: String?
    let menu_image_url: String
    let analysis_data: String
    let poll_options: [String]
    let expires_at: String
    let is_active: Bool
    let allow_multiple_votes: Bool
    let created_at: String
    let updated_at: String
}

struct PollRecipientInsert: Codable {
    let id: String
    let poll_id: String
    let recipient_id: String
    let has_voted: Bool
    let created_at: String
}

struct VoteInsert: Codable {
    let id: String
    let poll_id: String
    let voter_id: String
    let selected_dishes: [String]
    let vote_comment: String?
    let created_at: String
    let updated_at: String
}

@Observable
final class PollManager {
    
    private let supabaseClient = supabase
    
    var pollState: PollState = .idle
    var polls: [MenuPoll] = []
    
    init() {
        print("🗳️ PollManager: Initialized")
    }
    
    // MARK: - Poll Creation
    
    /// Create a new menu poll with the given configuration and recipients
    func createPoll(
        analysisResponse: MenuAnalysisResponse,
        menuImageUrl: String,
        configuration: PollConfiguration,
        selectedFriends: [UserProfile],
        currentUser: UserProfile
    ) async {
        print("🗳️ PollManager: Starting poll creation...")
        pollState = .creating
        
        do {
            // Extract dish names for poll options
            let pollOptions = analysisResponse.analysis.dishes.map { $0.dishName }
            print("🗳️ PollManager: Poll options: \(pollOptions)")
            
            // Create the poll in the database
            let poll = try await insertPoll(
                analysisResponse: analysisResponse,
                menuImageUrl: menuImageUrl,
                configuration: configuration,
                pollOptions: pollOptions,
                currentUser: currentUser
            )
            
            // Add recipients
            try await insertPollRecipients(pollId: poll.id, recipients: selectedFriends)
            
            print("🗳️ PollManager: Poll created successfully with ID: \(poll.id)")
            pollState = .success(poll)
            
            // Add to local polls list
            polls.insert(poll, at: 0)
            
        } catch {
            print("❌ PollManager: Failed to create poll: \(error)")
            pollState = .error("Failed to create poll: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Database Operations
    
    /// Insert poll into database
    private func insertPoll(
        analysisResponse: MenuAnalysisResponse,
        menuImageUrl: String,
        configuration: PollConfiguration,
        pollOptions: [String],
        currentUser: UserProfile
    ) async throws -> MenuPoll {
        
        let pollId = UUID()
        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        
        // Create poll insert model
        let pollInsert = PollInsert(
            id: pollId.uuidString,
            creator_id: currentUser.id.uuidString,
            title: configuration.question.isEmpty ? nil : configuration.question,
            description: configuration.description.isEmpty ? nil : configuration.description,
            menu_image_url: menuImageUrl,
            analysis_data: try encodeAnalysisResponse(analysisResponse),
            poll_options: pollOptions,
            expires_at: isoFormatter.string(from: configuration.expiresAt),
            is_active: true,
            allow_multiple_votes: configuration.allowMultipleVotes,
            created_at: isoFormatter.string(from: now),
            updated_at: isoFormatter.string(from: now)
        )
        
        print("🗳️ PollManager: Inserting poll with ID: \(pollId)")
        
        try await supabaseClient
            .from("menu_polls")
            .insert(pollInsert)
            .execute()
        
        // Return the poll object
        return MenuPoll(
            id: pollId,
            creatorId: currentUser.id,
            title: configuration.question.isEmpty ? nil : configuration.question,
            description: configuration.description.isEmpty ? nil : configuration.description,
            menuImageUrl: menuImageUrl,
            analysisData: analysisResponse,
            pollOptions: pollOptions,
            expiresAt: configuration.expiresAt,
            isActive: true,
            allowMultipleVotes: configuration.allowMultipleVotes,
            createdAt: now,
            updatedAt: now,
            creator: currentUser
        )
    }
    
    /// Insert poll recipients into database
    private func insertPollRecipients(pollId: UUID, recipients: [UserProfile]) async throws {
        let recipientInserts = recipients.map { recipient in
            PollRecipientInsert(
                id: UUID().uuidString,
                poll_id: pollId.uuidString,
                recipient_id: recipient.id.uuidString,
                has_voted: false,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        print("🗳️ PollManager: Inserting \(recipientInserts.count) poll recipients")
        
        try await supabaseClient
            .from("poll_recipients")
            .insert(recipientInserts)
            .execute()
    }
    
    // MARK: - Fetch Polls
    
    /// Fetch polls created by or shared with the current user
    func fetchUserPolls(currentUser: UserProfile) async {
        do {
            print("🗳️ PollManager: Fetching polls for user: \(currentUser.username)")
            
            // For now, just get basic poll data without joins to simplify
            struct PollResponse: Codable {
                let id: String
                let creator_id: String
                let title: String?
                let description: String?
                let menu_image_url: String
                let analysis_data: String
                let poll_options: [String]
                let expires_at: String
                let is_active: Bool
                let allow_multiple_votes: Bool
                let created_at: String
                let updated_at: String
            }
            
            // Query polls where user is creator or recipient
            let pollResponses: [PollResponse] = try await supabaseClient
                .from("menu_polls")
                .select("*")
                .or("creator_id.eq.\(currentUser.id.uuidString),poll_recipients.recipient_id.eq.\(currentUser.id.uuidString)")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Convert to MenuPoll objects
            let isoFormatter = ISO8601DateFormatter()
            polls = pollResponses.compactMap { pollResponse in
                guard let pollId = UUID(uuidString: pollResponse.id),
                      let creatorId = UUID(uuidString: pollResponse.creator_id),
                      let expiresAt = isoFormatter.date(from: pollResponse.expires_at),
                      let createdAt = isoFormatter.date(from: pollResponse.created_at),
                      let updatedAt = isoFormatter.date(from: pollResponse.updated_at),
                      let analysisData = try? decodeAnalysisResponse(pollResponse.analysis_data) else {
                    return nil
                }
                
                return MenuPoll(
                    id: pollId,
                    creatorId: creatorId,
                    title: pollResponse.title,
                    description: pollResponse.description,
                    menuImageUrl: pollResponse.menu_image_url,
                    analysisData: analysisData,
                    pollOptions: pollResponse.poll_options,
                    expiresAt: expiresAt,
                    isActive: pollResponse.is_active,
                    allowMultipleVotes: pollResponse.allow_multiple_votes,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            }
            
            print("🗳️ PollManager: Successfully fetched \(polls.count) polls")
            
        } catch {
            print("❌ PollManager: Failed to fetch polls: \(error)")
        }
    }
    
    // MARK: - Voting
    
    /// Submit a vote for a poll
    func submitVote(
        pollId: UUID,
        selectedDishes: [String],
        comment: String?,
        currentUser: UserProfile
    ) async throws {
        
        let voteInsert = VoteInsert(
            id: UUID().uuidString,
            poll_id: pollId.uuidString,
            voter_id: currentUser.id.uuidString,
            selected_dishes: selectedDishes,
            vote_comment: comment,
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        print("🗳️ PollManager: Submitting vote for poll: \(pollId)")
        
        try await supabaseClient
            .from("poll_votes")
            .insert(voteInsert)
            .execute()
        
        // Update recipient record to mark as voted
        try await supabaseClient
            .from("poll_recipients")
            .update(["has_voted": true])
            .eq("poll_id", value: pollId.uuidString)
            .eq("recipient_id", value: currentUser.id.uuidString)
            .execute()
        
        print("🗳️ PollManager: Vote submitted successfully")
    }
    
    // MARK: - Helper Methods
    
    /// Reset poll state
    func resetState() {
        pollState = .idle
    }
    
    /// Encode analysis response to JSON string
    private func encodeAnalysisResponse(_ analysisResponse: MenuAnalysisResponse) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(analysisResponse)
        return String(data: jsonData, encoding: .utf8)!
    }
    
    /// Decode analysis response from JSON string
    private func decodeAnalysisResponse(_ jsonString: String) throws -> MenuAnalysisResponse {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "PollManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string"])
        }
        let decoder = JSONDecoder()
        return try decoder.decode(MenuAnalysisResponse.self, from: jsonData)
    }
}
