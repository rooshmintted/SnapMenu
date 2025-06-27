//
//  ProfileView.swift
//  Menu Crimes
//
//  User profile management and settings
//

import SwiftUI

struct ProfileView: View {
    let authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var website = ""
    @State private var showingImagePicker = false
    @State private var avatarImage: UIImage?
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Profile Header
                ProfileHeaderView(
                    user: authManager.authState.currentUser,
                    avatarImage: avatarImage,
                    onEditPhoto: { showingImagePicker = true }
                )
                .padding(.bottom, 30)
                
                // Profile Form
                Form {
                    Section("Profile Information") {
                        HStack {
                            Text("Username")
                            Spacer()
                            Text("@\(authManager.authState.currentUser?.username ?? "")")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Website")
                            Spacer()
                            TextField("Website", text: $website)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.primary)
                                .keyboardType(.URL)
                        }
                    }
                    
                    Section("App Settings") {
                        NavigationLink(destination: NotificationSettingsView()) {
                            Label("Notifications", systemImage: "bell")
                        }
                        
                        NavigationLink(destination: PrivacySettingsView()) {
                            Label("Privacy & Safety", systemImage: "shield")
                        }
                        
                        NavigationLink(destination: AboutView()) {
                            Label("About", systemImage: "info.circle")
                        }
                    }
                    
                    Section {
                        Button("Sign Out") {
                            showingSignOutAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HelpButton()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(.orange)
                    .disabled(authManager.isLoading)
                }
            }
            .onAppear {
                loadProfileData()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(
                    selectedImage: $avatarImage,
                    isPresented: $showingImagePicker
                )
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private func loadProfileData() {
        if let user = authManager.authState.currentUser {
            website = user.website ?? ""
        }
    }
    
    private func saveProfile() {
        Task {
            await authManager.updateProfile(
                avatarUrl: nil, // TODO: Handle avatar upload
                website: website.isEmpty ? nil : website
            )
            
            if authManager.errorMessage == nil {
                dismiss()
            }
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let user: UserProfile?
    let avatarImage: UIImage?
    let onEditPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Avatar
            Button(action: onEditPhoto) {
                ZStack {
                    if let avatarImage = avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else if let avatarUrl = user?.avatarUrl, !avatarUrl.isEmpty {
                        AsyncImage(url: URL(string: avatarUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            DefaultAvatarView(username: user?.username ?? "")
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    } else {
                        DefaultAvatarView(username: user?.username ?? "")
                    }
                    
                    // Edit overlay
                    Circle()
                        .fill(.black.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "camera")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            
            // User Info
            VStack(spacing: 8) {
                Text(user?.username ?? "Unknown User")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("@\(user?.username ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Default Avatar View
struct DefaultAvatarView: View {
    let username: String
    
    var body: some View {
        Circle()
            .fill(.orange.gradient)
            .frame(width: 120, height: 120)
            .overlay(
                Text(username.prefix(2).uppercased())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Settings Views (Placeholders)
struct NotificationSettingsView: View {
    @State private var friendRequestNotifications = true
    @State private var menuAnalysisNotifications = true
    @State private var socialNotifications = true
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Friend Requests", isOn: $friendRequestNotifications)
                Toggle("Menu Analysis Complete", isOn: $menuAnalysisNotifications)
                Toggle("Social Activity", isOn: $socialNotifications)
            }
            
            Section(footer: Text("You can always change these settings later in the app.")) {
                EmptyView()
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    @State private var profileVisibility = "Friends Only"
    @State private var allowContactDiscovery = true
    @State private var shareAnalytics = false
    
    var body: some View {
        Form {
            Section("Profile Visibility") {
                Picker("Who can see your profile", selection: $profileVisibility) {
                    Text("Everyone").tag("Everyone")
                    Text("Friends Only").tag("Friends Only")
                    Text("Private").tag("Private")
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Section("Discovery") {
                Toggle("Allow friends to find you by phone number", isOn: $allowContactDiscovery)
            }
            
            Section("Data & Analytics") {
                Toggle("Share anonymous usage data", isOn: $shareAnalytics)
            }
            
            Section(footer: Text("Your privacy is important to us. We never share your personal information with third parties.")) {
                EmptyView()
            }
        }
        .navigationTitle("Privacy & Safety")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("Menu Crimes")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            Section("Support") {
                Link("Help Center", destination: URL(string: "https://example.com/help")!)
                Link("Contact Us", destination: URL(string: "mailto:support@menucrimes.com")!)
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
            }
            
            Section(footer: Text("Made with ❤️ for food lovers everywhere.")) {
                EmptyView()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView(authManager: AuthManager())
}
