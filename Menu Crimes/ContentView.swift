//
//  ContentView.swift
//  Menu Crimes
//
//  Main app interface with authentication and friend system integration
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Authentication and social managers - using @Observable pattern
    let authManager = AuthManager()
    let cameraManager = CameraManager()
    let galleryManager = PhotoGalleryManager()
    let photoShareManager = PhotoShareManager()
    let menuAnalysisManager = MenuAnalysisManager()
    
    // Lazy initialization of managers that depend on auth manager
    private var friendManager: FriendManager {
        FriendManager(authManager: authManager)
    }
    
    private var storyManager: StoryManager {
        StoryManager(authManager: authManager)
    }
    
    @State private var showTestView = false
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                LoadingView()
            case .unauthenticated, .error:
                VStack {
                    AuthContainerView(authManager: authManager)
                    
                    Button("Debug Supabase") {
                        showTestView = true
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                }
            case .authenticated:
                AuthenticatedMainView(
                    authManager: authManager,
                    cameraManager: cameraManager,
                    galleryManager: galleryManager,
                    friendManager: friendManager,
                    photoShareManager: photoShareManager,
                    storyManager: storyManager,
                    menuAnalysisManager: menuAnalysisManager
                )
            }
        }
        .onAppear {
            print("ContentView: App launched, checking authentication state")
        }
        .sheet(isPresented: $showTestView) {
            SupabaseTestView()
        }
    }
}

// MARK: - Authenticated Main View
struct AuthenticatedMainView: View {
    let authManager: AuthManager
    let cameraManager: CameraManager
    let galleryManager: PhotoGalleryManager
    let friendManager: FriendManager
    let photoShareManager: PhotoShareManager
    let storyManager: StoryManager
    let menuAnalysisManager: MenuAnalysisManager
    
    @State private var selectedTab = 0 // 0: Camera, 1: Analysis, 2: Friends
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Camera Tab (Main)
            if let currentUser = authManager.authState.currentUser {
                CameraView(
                    cameraManager: cameraManager, 
                    galleryManager: galleryManager,
                    friendManager: friendManager,
                    photoShareManager: photoShareManager,
                    storyManager: storyManager,
                    menuAnalysisManager: menuAnalysisManager,
                    currentUser: currentUser
                )
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "camera.fill" : "camera")
                        Text("Camera")
                    }
                    .tag(0)
                
                // Analysis Tab
                AnalysisView(
                    photoShareManager: photoShareManager,
                    currentUser: currentUser
                )
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                        Text("Analysis")
                    }
                    .tag(1)
                
                // Friends Tab (Updated)
                FriendsTabView(authManager: authManager, friendManager: friendManager, storyManager: storyManager)
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "person.2.fill" : "person.2")
                        Text("Friends")
                    }
                    .tag(2)
                    .conditionalBadge(friendManager.friendRequests.count)
            } else {
                // Fallback when user is not authenticated - this shouldn't normally happen
                // but prevents crashes during logout
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
            // Set default tab to camera for Snapchat-style experience
            selectedTab = 0
            
            // Configure tab bar appearance for better visibility
            configureTabBarAppearance()
            
            // Load friend data
            Task {
                await friendManager.loadFriends()
                await friendManager.loadFriendRequests()
            }
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

extension View {
    @ViewBuilder
    func conditionalBadge(_ count: Int) -> some View {
        if count > 0 {
            self.badge(count)
        } else {
            self
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
