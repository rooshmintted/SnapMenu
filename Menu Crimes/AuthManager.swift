//
//  AuthManager.swift
//  Menu Crimes
//
//  Handles user authentication with Supabase Auth
//

import Foundation
import Supabase
import SwiftUI

@Observable
final class AuthManager {
    var authState: AuthState = .loading
    var isLoading = false
    var errorMessage: String?
    
    init() {
        print("🔒 AuthManager: Initializing authentication manager")
        Task {
            await checkAuthState()
        }
    }
    
    // MARK: - Authentication State Management
    
    @MainActor
    func checkAuthState() async {
        print("🔐 AuthManager: Checking authentication state")
        isLoading = true
        
        do {
            let session = try await supabase.auth.session
            
            if session.user != nil {
                print("✅ AuthManager: User session found, fetching profile")
                await fetchUserProfile(userId: session.user.id)
                print(session.user.id)
            } else {
                print("ℹ️ AuthManager: No active session found")
                await setAuthState(.unauthenticated)
            }
        } catch {
            // Auth session missing is normal for first launch
            if error.localizedDescription.contains("Auth session missing") {
                print("ℹ️ AuthManager: No session found (first launch)")
                await setAuthState(.unauthenticated)
            } else {
                print("❌ AuthManager: Error checking auth state: \(error.localizedDescription)")
                await setAuthState(.error(error.localizedDescription))
            }
        }
    }
    
    @MainActor
    private func setAuthState(_ state: AuthState) {
        authState = state
        isLoading = false
        
        switch state {
        case .loading:
            print("🔒 AuthManager: State -> Loading")
        case .unauthenticated:
            print("🔒 AuthManager: State -> Unauthenticated")
        case .authenticated(let user):
            print("✅ AuthManager: State -> Authenticated as \(user.username)")
        case .error(let message):
            print("❌ AuthManager: State -> Error: \(message)")
            errorMessage = message
        }
    }
    
    // MARK: - Sign Up
    
    @MainActor
    func signUp(email: String, password: String, username: String) async {
        print("🔐 AuthManager: Starting sign up for \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            // Check if username is already taken
            print("🔐 AuthManager: Checking username availability...")
            let existingUsers: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("username", value: username)
                .execute()
                .value
            
            if !existingUsers.isEmpty {
                print("❌ AuthManager: Username '\(username)' is already taken")
                await setAuthState(.error("Username '\(username)' is already taken"))
                return
            }
            
            print("✅ AuthManager: Username is available")
            
            // Create auth user with additional metadata to help with profile creation
            print("🔐 AuthManager: Creating auth user...")
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "username": .string(username)
                ]
            )
            
            let user = authResponse.user
            print("✅ AuthManager: Auth user created with ID: \(user.id)")
            
            // Check if email confirmation is required
            if authResponse.session == nil {
                print("📧 AuthManager: Email confirmation required")
                await setAuthState(.error("Please check your email and click the confirmation link to complete registration."))
                return
            }
            
            // Wait a moment for any auto-profile creation to complete
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Update the auto-created profile with our username data
            print("🔐 AuthManager: Updating profile with username...")
            try await supabase
                .from("profiles")
                .update([
                    "username": username,
                    "display_name": username,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: user.id)
                .execute()
            
            print("✅ AuthManager: Profile updated successfully")
            
            // Fetch the updated profile
            await fetchUserProfile(userId: user.id)
            
        } catch {
            print("❌ AuthManager: Sign up error: \(error)")
            print("❌ AuthManager: Error details: \(error.localizedDescription)")
            await setAuthState(.error(error.localizedDescription))
        }
    }
    
    // MARK: - Sign In
    
    @MainActor
    func signIn(email: String, password: String) async {
        print("🔒 AuthManager: Starting sign in for \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            print("✅ AuthManager: Sign in successful")
            await fetchUserProfile(userId: session.user.id)
            
        } catch {
            print("❌ AuthManager: Sign in error: \(error.localizedDescription)")
            await setAuthState(.error(error.localizedDescription))
        }
    }
    
    // MARK: - Sign Out
    
    @MainActor
    func signOut() async {
        print("🔒 AuthManager: Starting sign out")
        isLoading = true
        
        do {
            try await supabase.auth.signOut()
            print("✅ AuthManager: Sign out successful")
            await setAuthState(.unauthenticated)
        } catch {
            print("❌ AuthManager: Sign out error: \(error.localizedDescription)")
            await setAuthState(.error(error.localizedDescription))
        }
    }
    
    // MARK: - Profile Management
    
    @MainActor
    private func fetchUserProfile(userId: UUID) async {
        do {
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            if let profile = profiles.first {
                print("👍 AuthManager: User profile fetched successfully")
                await setAuthState(.authenticated(profile))
            } else {
                print("ℹ️ AuthManager: User profile not found")
                await setAuthState(.error("User profile not found"))
            }
        } catch {
            print("❌ AuthManager: Error fetching user profile: \(error.localizedDescription)")
            await setAuthState(.error(error.localizedDescription))
        }
    }
    
    @MainActor
    func updateProfile(avatarUrl: String?, website: String?) async {
        guard case .authenticated(let currentUser) = authState else {
            print("🔒 AuthManager: Cannot update profile - user not authenticated")
            return
        }
        
        print("🔒 AuthManager: Updating user profile")
        isLoading = true
        
        do {
            let updatedProfile = UserProfile(
                id: currentUser.id,
                username: currentUser.username,
                avatarUrl: avatarUrl,
                website: website,
                updatedAt: Date()
            )
            
            try await supabase
                .from("profiles")
                .update(updatedProfile)
                .eq("id", value: currentUser.id)
                .execute()
            
            print("👍 AuthManager: Profile updated successfully")
            await setAuthState(.authenticated(updatedProfile))
            
        } catch {
            print("❌ AuthManager: Error updating profile: \(error.localizedDescription)")
            await setAuthState(.error(error.localizedDescription))
        }
    }
    
    // MARK: - Password Reset
    
    @MainActor
    func resetPassword(email: String) async {
        print("🔒 AuthManager: Sending password reset for \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("✅ AuthManager: Password reset email sent")
            isLoading = false
        } catch {
            print("❌ AuthManager: Password reset error: \(error.localizedDescription)")
            await setAuthState(.error(error.localizedDescription))
        }
    }
}
