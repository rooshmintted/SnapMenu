//
//  ContentView.swift
//  Menu Crimes
//
//  Main app interface with authentication and menu analysis
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Core managers - using @Observable pattern
    let authManager = AuthManager()
    let cameraManager = CameraManager()
    let galleryManager = PhotoGalleryManager()
    let menuAnalysisManager = MenuAnalysisManager()
    let menuAnnotationManager = MenuAnnotationManager()
    let onboardingManager = OnboardingManager()
    
    // Stats manager for tracking menu analysis statistics
    @State private var statsManager: StatsManager?
    
    var body: some View {
        Group {
            // Check onboarding first - show onboarding before authentication if not completed
            if !onboardingManager.hasCompletedOnboarding {
                OnboardingView {
                    print("🎯 ContentView: Onboarding completed, now checking authentication")
                    onboardingManager.markOnboardingCompleted()
                }
            } else {
                // Onboarding completed, now handle authentication flow
                switch authManager.authState {
                case .loading:
                    LoadingView()
                case .unauthenticated, .error:
                    AuthContainerView(authManager: authManager)
                case .authenticated:
                    if let statsManager = statsManager {
                        AuthenticatedMainView(
                            authManager: authManager,
                            cameraManager: cameraManager,
                            galleryManager: galleryManager,
                            menuAnalysisManager: menuAnalysisManager,
                            menuAnnotationManager: menuAnnotationManager,
                            statsManager: statsManager
                        )
                    } else {
                        LoadingView()
                    }
                }
            }
        }
        .onAppear {
            print("ContentView: App launched, checking authentication state")
            print("🎯 ContentView: Onboarding completed: \(onboardingManager.hasCompletedOnboarding)")
            
            // Initialize StatsManager
            if statsManager == nil {
                statsManager = StatsManager(viewContext: viewContext)
                print("📊 ContentView: StatsManager initialized")
            }
            
            Task {
                await authManager.checkAuthState()
                
                // Load user stats when authenticated
                if case .authenticated = authManager.authState,
                   let userID = authManager.authState.currentUser?.id {
                    await statsManager?.loadUserStats(for: userID.uuidString)
                }
            }
        }
    }
}

// MARK: - Authenticated Main View
struct AuthenticatedMainView: View {
    let authManager: AuthManager
    let cameraManager: CameraManager
    let galleryManager: PhotoGalleryManager
    let menuAnalysisManager: MenuAnalysisManager
    let menuAnnotationManager: MenuAnnotationManager
    let statsManager: StatsManager
    
    @State private var selectedTab = 0 // 0: Camera, 1: Search, 2: Profile
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Camera Tab (Main)
            if let currentUser = authManager.authState.currentUser {
                CameraView(
                    cameraManager: cameraManager, 
                    galleryManager: galleryManager,
                    menuAnalysisManager: menuAnalysisManager,
                    menuAnnotationManager: menuAnnotationManager,
                    currentUser: currentUser
                )
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "camera.fill" : "camera")
                        Text("Camera")
                    }
                    .tag(0)
                
                // Search Tab - ChatGPT-style menu search
                SearchView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                        Text("Ask")
                    }
                    .tag(1)
                
                // Profile Tab
                ProfileView(authManager: authManager, statsManager: statsManager)
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                        Text("Profile")
                    }
                    .tag(2)
            } else {
                // Fallback when user is not authenticated
                Text("Loading...")
                    .tabItem {
                        Image(systemName: "camera")
                        Text("Camera")
                    }
                    .tag(0)
            }
        }
        .accentColor(.orange) // Menu Crimes brand color
        .tabViewStyle(.automatic)
        .onAppear {
            print("AuthenticatedMainView: User authenticated, showing main interface")
            // Set default tab to camera for camera-first experience
            selectedTab = 0
            
            // Connect StatsManager to MenuAnalysisManager for stats tracking
            menuAnalysisManager.statsManager = statsManager
            print("📊 AuthenticatedMainView: Connected StatsManager to MenuAnalysisManager")
            
            // Configure tab bar appearance for better visibility
            configureTabBarAppearance()
        }
    }
    
    // MARK: - Tab Bar Configuration
    private func configureTabBarAppearance() {
        print("🔧 ContentView: Configuring tab bar appearance for visibility")
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Configure normal state (unselected tabs)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.orange
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.orange
        ]
        
        // Configure selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.orange
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.orange
        ]
        
        // Apply to all tab bars
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor.orange
        UITabBar.appearance().unselectedItemTintColor = UIColor.orange.withAlphaComponent(0.6)
    }
}

#Preview {
    ContentView()
}
