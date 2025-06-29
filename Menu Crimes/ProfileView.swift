//
//  ProfileView.swift
//  Menu Crimes
//
//  Gamified user profile with menu submission stats
//

import SwiftUI

struct ProfileView: View {
    let authManager: AuthManager
    let statsManager: StatsManager
    @State private var showingSignOutAlert = false
    @State private var showingOnboarding = false // Added for help button functionality
    @State private var editingProfile = false // Added for profile editing functionality
    
    // Computed properties to simplify complex expressions
    private var milestoneProgress: Double {
        statsManager.getMilestoneProgress().progress
    }
    
    private var progressBarWidth: CGFloat {
        max(0, CGFloat(milestoneProgress) * UIScreen.main.bounds.width * 0.8)
    }
    
    private var progressPercentage: Int {
        Int(milestoneProgress * 100)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with username and help
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello,")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        if let currentUser = authManager.authState.currentUser {
                            Text("@\(currentUser.username)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // Help button
                    Button(action: {
                        print("🎯 ProfileView: Help button tapped - showing onboarding")
                        showingOnboarding = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Modern Stats Section
                VStack(spacing: 20) {
                        HStack {
                            Text("Your Analytics")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        // Premium Stats Cards
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                ModernStatsCard(
                                    title: "Menus Analyzed",
                                    value: "\(statsManager.menusSubmitted)",
                                    icon: "camera.fill",
                                    color: .orange
                                )
                                
                                ModernStatsCard(
                                    title: "Dishes Discovered",
                                    value: "\(statsManager.dishesAnalyzed)",
                                    icon: "fork.knife",
                                    color: .blue
                                )
                            }
                            
                            // Premium Progress Section
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Progress to Menu Master")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("\(progressPercentage)% complete")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    ZStack {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                            .frame(width: 50, height: 50)
                                        
                                        Circle()
                                            .trim(from: 0, to: CGFloat(milestoneProgress))
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.orange, .red],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                            )
                                            .frame(width: 50, height: 50)
                                            .rotationEffect(.degrees(-90))
                                    }
                                }
                                
                                // Modern progress bar
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [.orange, .red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: progressBarWidth, height: 8)
                                }
                            }
                            .padding(20)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Premium Achievements Section
                    VStack(spacing: 20) {
                        HStack {
                            Text("Achievements")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            let achievements = statsManager.getAchievementStatus()
                            
                            ModernAchievementRow(
                                title: "First Menu",
                                description: "Analyzed your first menu",
                                isUnlocked: achievements["first_menu"] ?? false,
                                icon: "camera.fill",
                                color: .green
                            )
                            
                            ModernAchievementRow(
                                title: "Menu Explorer",
                                description: "Analyzed 10 menus",
                                isUnlocked: achievements["menu_explorer"] ?? false,
                                icon: "map.fill",
                                color: .blue
                            )
                            
                            ModernAchievementRow(
                                title: "Dish Detective",
                                description: "Analyzed 50 dishes",
                                isUnlocked: achievements["dish_detective"] ?? false,
                                icon: "magnifyingglass",
                                color: .purple
                            )
                            
                            ModernAchievementRow(
                                title: "Menu Master",
                                description: "Analyzed 25 menus",
                                isUnlocked: achievements["menu_master"] ?? false,
                                icon: "crown.fill",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Premium Help Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Get Started")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        Button(action: {
                            print("🎯 ProfileView: Help button tapped - showing onboarding")
                            showingOnboarding = true
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("How to Use Menu AI")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("Learn about menu analysis and discovery")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
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
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView {
                    // Handle onboarding completion
                    print("🎯 ProfileView: Onboarding completed from help button")
                    showingOnboarding = false
                }
            }
        }
    }


// MARK: - Supporting Components

/// Gamified stats card showing user metrics
// MARK: - Modern Stats Card
/// Premium stats card with enhanced visual design
struct ModernStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Legacy compatibility wrapper
struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        ModernStatsCard(title: title, value: value, icon: icon, color: color)
    }
}

/// Achievement row showing unlocked and locked achievements
// MARK: - Modern Achievement Row
/// Premium achievement display with enhanced visual feedback
struct ModernAchievementRow: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isUnlocked ? color : .gray)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 30, height: 30)
                
                Image(systemName: isUnlocked ? "checkmark" : "lock")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isUnlocked ? .green : .gray)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? color.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isUnlocked ? 1.0 : 0.98)
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

// Legacy compatibility wrapper
struct AchievementRow: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        ModernAchievementRow(title: title, description: description, isUnlocked: isUnlocked, icon: icon, color: color)
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
    ProfileView(
        authManager: AuthManager(),
        statsManager: StatsManager(viewContext: PersistenceController.preview.container.viewContext)
    )
}
