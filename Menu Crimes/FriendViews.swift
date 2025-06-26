//
//  FriendViews.swift
//  Menu Crimes
//
//  Friend system UI components for managing friends and social interactions
//

import SwiftUI

// MARK: - Friends Tab View
struct FriendsTabView: View {
    let authManager: AuthManager
    let friendManager: FriendManager
    let storyManager: StoryManager
    
    @State private var showingAddFriends = false
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Friends Content
                friendsTabContent
                
                Spacer()
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFriends = true }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .task {
                print("👥 FriendsTabView: Loading friends and requests")
                await friendManager.loadFriends()
                await friendManager.loadFriendRequests()
            }
            .refreshable {
                print("👥 FriendsTabView: Refreshing friends data")
                await friendManager.loadFriends()
                await friendManager.loadFriendRequests()
            }
        }
        .sheet(isPresented: $showingAddFriends) {
            AddFriendsView(friendManager: friendManager)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(authManager: authManager)
        }
    }
    
    // MARK: - Friends Tab Content
    @ViewBuilder
    private var friendsTabContent: some View {
        // Friend Requests Section
        if !friendManager.friendRequests.isEmpty {
            FriendRequestsSection(friendManager: friendManager)
                .padding(.bottom, 10)
        }
        
        // Friends List
        if friendManager.friends.isEmpty && !friendManager.isLoading {
            EmptyFriendsView(onAddFriends: { showingAddFriends = true })
        } else {
            FriendsListView(friends: friendManager.friends, storyManager: storyManager)
        }
    }
}

// MARK: - Empty Friends View
struct EmptyFriendsView: View {
    let onAddFriends: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 15) {
                Text("No Friends Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Connect with friends to share menu discoveries and get dining recommendations.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Add Friends") {
                onAddFriends()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(Capsule().fill(.orange))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Friends List View
struct FriendsListView: View {
    let friends: [UserProfile]
    let storyManager: StoryManager
    
    @State private var selectedFriend: UserProfile?
    @State private var showingStoryView = false
    
    var body: some View {
        List(friends) { friend in
            HStack {
                // Profile image placeholder with story ring
                ZStack {
                    // Story ring indicator
                    if storyManager.hasStories(for: friend.id) {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .red]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 52, height: 52)
                    }
                    
                    // Profile image
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(friend.username.prefix(2).uppercased())
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.username)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if storyManager.hasStories(for: friend.id) {
                        Text("Tap to view story")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .onAppear {
                                // Preload stories in background when story indicator appears
                                Task {
                                    await storyManager.preloadStoriesForFriend(friend)
                                }
                            }
                    } else {
                        Text("@\(friend.username)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if storyManager.hasStories(for: friend.id) {
                    print("👆 FriendsListView: Tapped friend \(friend.username) with stories")
                    selectedFriend = friend
                    
                    // Validate that we actually have stories before opening
                    let stories = storyManager.getStories(for: friend.id)
                    print("📱 FriendsListView: Found \(stories.count) stories for \(friend.username)")
                    
                    if !stories.isEmpty {
                        showingStoryView = true
                    } else {
                        print("❌ FriendsListView: No stories found despite hasStories returning true")
                    }
                } else {
                    print("👆 FriendsListView: Tapped friend \(friend.username) with no stories")
                    // Could navigate to friend detail view or profile
                }
            }
        }
        .listStyle(PlainListStyle())
        .onAppear {
            print("👥 FriendsListView: Loading friend stories")
            Task {
                // Load all friend stories first
                await storyManager.loadFriendStories(for: friends)
                
                // Then preload stories for friends who have them (background operation)
                for friend in friends {
                    if storyManager.hasStories(for: friend.id) {
                        await storyManager.preloadStoriesForFriend(friend)
                    }
                }
            }
        }
        .sheet(isPresented: $showingStoryView) {
            if let friend = selectedFriend {
                let stories = storyManager.getStories(for: friend.id)
                
                if !stories.isEmpty {
                    StoryPopupView(
                        stories: stories,
                        username: friend.username,
                        storyManager: storyManager
                    )
                } else {
                    // Fallback view if no stories
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Stories Available")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Button("Close") {
                            showingStoryView = false
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Friend Requests Section
struct FriendRequestsSection: View {
    let friendManager: FriendManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Friend Requests")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(friendManager.friendRequests.count)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.orange))
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(friendManager.friendRequests) { request in
                        FriendRequestCard(request: request, friendManager: friendManager)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - Friend Request Card
struct FriendRequestCard: View {
    let request: FriendRequest
    let friendManager: FriendManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: request.sender?.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .overlay(
                        Text((request.sender?.username ?? "").prefix(2).uppercased())
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            // Sender Info
            VStack(spacing: 4) {
                Text(request.sender?.username ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("@\(request.sender?.username ?? "")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        await friendManager.acceptFriendRequest(request)
                    }
                }) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.green))
                }
                
                Button(action: {
                    Task {
                        await friendManager.rejectFriendRequest(request)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.red))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .frame(width: 140)
    }
}

// MARK: - Add Friends View
struct AddFriendsView: View {
    let friendManager: FriendManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [UserProfile] = []
    @State private var selectedTab = 0 // 0: Search, 1: Contacts
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Picker
                Picker("Add Friends Method", selection: $selectedTab) {
                    Text("Search").tag(0)
                    Text("Contacts").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    SearchFriendsView(
                        friendManager: friendManager,
                        searchText: $searchText,
                        searchResults: $searchResults
                    )
                } else {
                    ContactFriendsView(friendManager: friendManager)
                }
            }
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Search Friends View
struct SearchFriendsView: View {
    let friendManager: FriendManager
    @Binding var searchText: String
    @Binding var searchResults: [UserProfile]
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                .padding(.horizontal)
            
            if searchResults.isEmpty && !searchText.isEmpty {
                EmptySearchResultsView()
            } else {
                List(searchResults) { user in
                    UserSearchResultRow(user: user, friendManager: friendManager)
                        .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func performSearch() {
        print("👥 SearchFriendsView: Searching for users with query: \(searchText)")
        Task {
            searchResults = await friendManager.searchUsers(query: searchText)
        }
    }
}

// MARK: - Contact Friends View
struct ContactFriendsView: View {
    let friendManager: FriendManager
    
    var body: some View {
        VStack {
            if friendManager.contactFriends.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("Find Friends from Contacts")
                        .font(.headline)
                    
                    Text("We'll help you find friends who are already using Menu Crimes.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Search Contacts") {
                        Task {
                            await friendManager.findFriendsFromContacts()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(.orange))
                    .disabled(friendManager.isLoading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(friendManager.contactFriends) { user in
                    UserSearchResultRow(user: user, friendManager: friendManager)
                        .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            if friendManager.contactFriends.isEmpty {
                Task {
                    await friendManager.findFriendsFromContacts()
                }
            }
        }
    }
}

// MARK: - User Search Result Row
struct UserSearchResultRow: View {
    let user: UserProfile
    let friendManager: FriendManager
    
    @State private var requestSent = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .overlay(
                        Text(user.username.prefix(2).uppercased())
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Add Friend Button
            if requestSent {
                Text("Sent")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.gray.opacity(0.2)))
            } else {
                Button("Add") {
                    Task {
                        await friendManager.sendFriendRequest(to: user.id)
                        requestSent = true
                    }
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(.orange))
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search by username or email", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("Search", action: onSearchButtonClicked)
                .foregroundColor(.orange)
                .disabled(text.isEmpty)
        }
    }
}

// MARK: - Empty Search Results View
struct EmptySearchResultsView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Users Found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Try searching with a different username or email.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FriendsTabView(
        authManager: AuthManager(),
        friendManager: FriendManager(authManager: AuthManager()),
        storyManager: StoryManager()
    )
}
