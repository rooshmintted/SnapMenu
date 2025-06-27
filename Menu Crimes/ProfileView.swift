//
//  ProfileView.swift
//  Menu Crimes
//
//  Gamified user profile with menu submission stats
//

import SwiftUI

struct ProfileView: View {
    let authManager: AuthManager
    @State private var showingSignOutAlert = false
    
    // Mock data for gamification - will be pulled from Supabase later
    @State private var menusSubmitted = 27
    @State private var dishesAnalyzed = 143
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with username and help
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello,")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("@\(authManager.authState.currentUser?.username ?? "user")")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // Help button
                    Button {
                        print("Help button tapped") // Debug log
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Gamified Stats Cards
                VStack(spacing: 16) {
                    // Menu Detective Badge
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Menu Detective")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Keep analyzing menus to unlock new badges!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.orange.opacity(0.1))
                            .stroke(.orange.opacity(0.3), lineWidth: 1)
                    }
                    
                    // Stats Grid
                    HStack(spacing: 16) {
                        // Menus Submitted
                        StatsCard(
                            title: "Menus\nSubmitted",
                            value: "\(menusSubmitted)",
                            icon: "camera.fill",
                            color: .blue,
                            description: "Photos uploaded"
                        )
                        
                        // Dishes Analyzed
                        StatsCard(
                            title: "Dishes\nAnalyzed",
                            value: "\(dishesAnalyzed)",
                            icon: "fork.knife",
                            color: .green,
                            description: "Items reviewed"
                        )
                    }
                    
                    // Progress to next milestone
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Next Milestone")
                                .font(.headline)
                            Spacer()
                            Text("\(menusSubmitted)/50")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: Double(menusSubmitted), total: 50.0)
                            .tint(.orange)
                        
                        Text("🏆 Upload 50 menus to earn 'Master Analyst' badge")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    }
                    
                    // Achievements Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Achievements")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            AchievementRow(
                                icon: "camera.badge.ellipsis",
                                title: "First Menu",
                                description: "Uploaded your first menu photo",
                                isUnlocked: true
                            )
                            
                            AchievementRow(
                                icon: "10.circle.fill",
                                title: "Getting Started",
                                description: "Analyzed 10 menu items",
                                isUnlocked: true
                            )
                            
                            AchievementRow(
                                icon: "star.circle",
                                title: "Menu Expert",
                                description: "Submit 100 menus",
                                isUnlocked: false
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 24)
                
                // Sign Out Button
                Button {
                    showingSignOutAlert = true
                    print("Sign out button tapped") // Debug log
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.red.opacity(0.3), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    print("Signing out user") // Debug log
                    await authManager.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Supporting Components

/// Gamified stats card showing user metrics
struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            // Value
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Description
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
    }
}

/// Achievement row showing unlocked and locked achievements
struct AchievementRow: View {
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Achievement icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? .orange : .gray)
                .frame(width: 32, height: 32)
            
            // Achievement details
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Lock/unlock indicator
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "lock.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
        }
    }
}

// MARK: - Help Button Component
struct HelpButton: View {
    var body: some View {
        Button {
            print("Help button tapped - would show help content") // Debug log
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.title2)
                .foregroundColor(.orange)
        }
    }
}

#Preview {
    ProfileView(authManager: AuthManager())
}
