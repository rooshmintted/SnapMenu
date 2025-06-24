//
//  FriendManager.swift
//  Menu Crimes
//
//  Manages friend relationships, requests, and social interactions
//

import Foundation
import Supabase
import Contacts

@Observable
final class FriendManager {
    var friends: [UserProfile] = []
    var friendRequests: [FriendRequest] = []
    var sentRequests: [FriendRequest] = []
    var contactFriends: [UserProfile] = []
    var isLoading = false
    var errorMessage: String?
    
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        print("👥 FriendManager: Initializing friend manager")
    }
    
    // MARK: - Friend Management
    
    @MainActor
    func loadFriends() async {
        guard let currentUser = authManager.authState.currentUser else {
            print("❌ FriendManager: Cannot load friends - user not authenticated")
            return
        }
        
        print("👥 FriendManager: Loading friends for user \(currentUser.username)")
        isLoading = true
        
        do {
            // Query friendships where current user is either user1 or user2
            // Simplified query to avoid table name duplication
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("user_id1.eq.\(currentUser.id),user_id2.eq.\(currentUser.id)")
                .execute()
                .value
            
            // Extract friend profiles by fetching each friend individually
            var friendProfiles: [UserProfile] = []
            for friendship in friendships {
                let friendId = friendship.getFriendId(for: currentUser.id)
                
                // Fetch friend profile
                let profiles: [UserProfile] = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: friendId)
                    .execute()
                    .value
                
                if let friendProfile = profiles.first {
                    friendProfiles.append(friendProfile)
                }
            }
            
            friends = friendProfiles
            print("✅ FriendManager: Loaded \(friends.count) friends")
            
        } catch {
            print("❌ FriendManager: Error loading friends: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadFriendRequests() async {
        guard let currentUser = authManager.authState.currentUser else {
            print("❌ FriendManager: Cannot load friend requests - user not authenticated")
            return
        }
        
        print("👥 FriendManager: Loading friend requests")
        isLoading = true
        
        do {
            // Load incoming friend requests
            let incomingRequests: [FriendRequest] = try await supabase
                .from("friend_requests")
                .select("*, sender:profiles!sender_id(*)")
                .eq("receiver_id", value: currentUser.id)
                .eq("status", value: FriendRequestStatus.pending.rawValue)
                .execute()
                .value
            
            // Load outgoing friend requests
            let outgoingRequests: [FriendRequest] = try await supabase
                .from("friend_requests")
                .select("*, receiver:profiles!receiver_id(*)")
                .eq("sender_id", value: currentUser.id)
                .eq("status", value: FriendRequestStatus.pending.rawValue)
                .execute()
                .value
            
            friendRequests = incomingRequests
            sentRequests = outgoingRequests
            
            print("✅ FriendManager: Loaded \(friendRequests.count) incoming and \(sentRequests.count) outgoing requests")
            
        } catch {
            print("❌ FriendManager: Error loading friend requests: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Friend Requests
    
    @MainActor
    func sendFriendRequest(to userId: UUID) async {
        guard let currentUser = authManager.authState.currentUser else {
            print("❌ FriendManager: Cannot send friend request - user not authenticated")
            return
        }
        
        print("👥 FriendManager: Sending friend request to user \(userId)")
        
        do {
            // Check if request already exists
            let existingRequests: [FriendRequest] = try await supabase
                .from("friend_requests")
                .select()
                .eq("sender_id", value: currentUser.id)
                .eq("receiver_id", value: userId)
                .execute()
                .value
            
            if !existingRequests.isEmpty {
                print("⚠️ FriendManager: Friend request already exists")
                errorMessage = "Friend request already sent"
                return
            }
            
            // Check if already friends
            let existingFriendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("and(user_id1.eq.\(currentUser.id),user_id2.eq.\(userId)),and(user_id1.eq.\(userId),user_id2.eq.\(currentUser.id))")
                .execute()
                .value
            
            if !existingFriendships.isEmpty {
                print("⚠️ FriendManager: Users are already friends")
                errorMessage = "You are already friends with this user"
                return
            }
            
            // Create friend request
            let request = FriendRequest(
                id: UUID(),
                senderId: currentUser.id,
                receiverId: userId,
                status: .pending,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await supabase
                .from("friend_requests")
                .insert(request)
                .execute()
            
            print("✅ FriendManager: Friend request sent successfully")
            await loadFriendRequests() // Refresh requests
            
        } catch {
            print("❌ FriendManager: Error sending friend request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func acceptFriendRequest(_ request: FriendRequest) async {
        print("👥 FriendManager: Accepting friend request from \(request.senderId)")
        
        do {
            // Update request status to accepted
            let dateFormatter = ISO8601DateFormatter()
            let updatedAt = dateFormatter.string(from: Date())
            
            try await supabase
                .from("friend_requests")
                .update(["status": FriendRequestStatus.accepted.rawValue, "updated_at": updatedAt])
                .eq("id", value: request.id)
                .execute()
            
            // Create friendship with proper ordering to avoid duplicates
            // Always put the smaller UUID first to ensure uniqueness
            let userId1 = min(request.senderId, request.receiverId)
            let userId2 = max(request.senderId, request.receiverId)
            
            let friendship = Friendship(
                id: UUID(),
                userId1: userId1,
                userId2: userId2,
                createdAt: Date()
            )
            
            // Try to insert friendship, ignore if it already exists
            do {
                try await supabase
                    .from("friendships")
                    .insert(friendship)
                    .execute()
                
                print("✅ FriendManager: Friendship created successfully")
            } catch {
                // Check if it's a duplicate key error (friendship already exists)
                if error.localizedDescription.contains("duplicate key value violates unique constraint") {
                    print("ℹ️ FriendManager: Friendship already exists, skipping creation")
                } else {
                    // Re-throw other errors
                    throw error
                }
            }
            
            // Refresh data
            await loadFriends()
            await loadFriendRequests()
            
        } catch {
            print("❌ FriendManager: Error accepting friend request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func rejectFriendRequest(_ request: FriendRequest) async {
        print("👥 FriendManager: Rejecting friend request from \(request.senderId)")
        
        do {
            let dateFormatter = ISO8601DateFormatter()
            let updatedAt = dateFormatter.string(from: Date())
            
            try await supabase
                .from("friend_requests")
                .update(["status": FriendRequestStatus.rejected.rawValue, "updated_at": updatedAt])
                .eq("id", value: request.id)
                .execute()
            
            print("✅ FriendManager: Friend request rejected")
            await loadFriendRequests() // Refresh requests
            
        } catch {
            print("❌ FriendManager: Error rejecting friend request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Contact Integration
    
    @MainActor
    func findFriendsFromContacts() async {
        print("👥 FriendManager: Finding friends from contacts")
        
        // Request contact access
        let contactStore = CNContactStore()
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        if status == .denied || status == .restricted {
            print("❌ FriendManager: Contact access denied")
            errorMessage = "Contact access is required to find friends"
            return
        }
        
        if status == .notDetermined {
            do {
                let granted = try await contactStore.requestAccess(for: .contacts)
                if !granted {
                    print("❌ FriendManager: Contact access not granted")
                    errorMessage = "Contact access is required to find friends"
                    return
                }
            } catch {
                print("❌ FriendManager: Error requesting contact access: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                return
            }
        }
        
        isLoading = true
        
        do {
            // Fetch contacts
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            var contacts: [ContactInfo] = []
            var phoneNumbers: [String] = []
            var emails: [String] = []
            
            try contactStore.enumerateContacts(with: request) { contact, _ in
                let contactInfo = ContactInfo(
                    firstName: contact.givenName,
                    lastName: contact.familyName,
                    phoneNumbers: contact.phoneNumbers.map { $0.value.stringValue },
                    emailAddresses: contact.emailAddresses.map { String($0.value) }
                )
                
                contacts.append(contactInfo)
                phoneNumbers.append(contentsOf: contactInfo.phoneNumbers)
                emails.append(contentsOf: contactInfo.emailAddresses)
            }
            
            // Find users in database matching contact info
            let matchingUsers: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .or("phone_number.in.(\(phoneNumbers.joined(separator: ","))),email.in.(\(emails.joined(separator: ",")))")
                .execute()
                .value
            
            // Filter out current user and existing friends/requests
            guard let currentUser = authManager.authState.currentUser else {
                contactFriends = []
                return
            }
            
            let filteredUsers = matchingUsers.filter { user in
                // Exclude current user
                user.id != currentUser.id &&
                // Exclude existing friends
                !friends.contains { $0.id == user.id } &&
                // Exclude users with pending requests
                !friendRequests.contains { $0.senderId == user.id } &&
                !sentRequests.contains { $0.receiverId == user.id }
            }
            
            contactFriends = filteredUsers
            print("✅ FriendManager: Found \(contactFriends.count) friends from \(contacts.count) contacts (filtered out current user and existing connections)")
            
        } catch {
            print("❌ FriendManager: Error finding friends from contacts: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Search Users
    
    @MainActor
    func searchUsers(query: String) async -> [UserProfile] {
        guard !query.isEmpty else { return [] }
        guard let currentUser = authManager.authState.currentUser else { return [] }
        
        print("👥 FriendManager: Searching users with query: \(query)")
        
        do {
            let users: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .or("username.ilike.%\(query)%")
                .neq("id", value: currentUser.id)  // Exclude current user from search
                .limit(20)
                .execute()
                .value
            
            // Additionally filter out existing friends and pending requests
            let filteredUsers = users.filter { user in
                // Exclude existing friends
                !friends.contains { $0.id == user.id } &&
                // Exclude users with pending requests
                !friendRequests.contains { $0.senderId == user.id } &&
                !sentRequests.contains { $0.receiverId == user.id }
            }
            
            print("✅ FriendManager: Found \(filteredUsers.count) users matching query (filtered out current user and existing connections)")
            return filteredUsers
            
        } catch {
            print("❌ FriendManager: Error searching users: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return []
        }
    }
}
