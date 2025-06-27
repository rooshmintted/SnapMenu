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
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                LoadingView()
            case .unauthenticated, .error:
                AuthContainerView(authManager: authManager)
            case .authenticated:
                if !onboardingManager.hasCompletedOnboarding {
                    // Show onboarding on first launch
                    OnboardingView {
                        onboardingManager.markOnboardingCompleted()
                    }
                } else {
                    AuthenticatedMainView(
                        authManager: authManager,
                        cameraManager: cameraManager,
                        galleryManager: galleryManager,
                        menuAnalysisManager: menuAnalysisManager,
                        menuAnnotationManager: menuAnnotationManager
                    )
                }
            }
        }
        .onAppear {
            print("ContentView: App launched, checking authentication state")
            print("🎯 ContentView: Onboarding completed: \(onboardingManager.hasCompletedOnboarding)")
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
                        Text("Search")
                    }
                    .tag(1)
                
                // Profile Tab
                ProfileView(authManager: authManager)
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
