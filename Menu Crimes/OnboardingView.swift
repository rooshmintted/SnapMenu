//
//  OnboardingView.swift
//  Menu Crimes
//
//  Onboarding screens for AskMrMenu: Clean, modern illustrations showing key features
//

import SwiftUI

// MARK: - Onboarding Manager
@Observable
class OnboardingManager {
    private let onboardingCompletedKey = "OnboardingCompleted"
    
    // Make this a published property that triggers UI updates
    var hasCompletedOnboarding: Bool {
        didSet {
            print("🎯 OnboardingManager: Onboarding state changed to: \(hasCompletedOnboarding)")
        }
    }
    
    init() {
        // Initialize from UserDefaults
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        print("🎯 OnboardingManager: Initialized with onboarding completed: \(hasCompletedOnboarding)")
    }
    
    func markOnboardingCompleted() {
        print("🎯 OnboardingManager: Marking onboarding as completed")
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        hasCompletedOnboarding = true // This triggers UI update
    }
    
    func resetOnboarding() {
        print("🔄 OnboardingManager: Resetting onboarding state")
        UserDefaults.standard.removeObject(forKey: onboardingCompletedKey)
        hasCompletedOnboarding = false // This triggers UI update
    }
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    private let onboardingData: [OnboardingPage] = [
        OnboardingPage(
            title: "Scan Menus with Ease",
            subtitle: "Capture any restaurant menu and let our AI extract every detail",
            imageName: "scan_menu_illustration", // You'll need to add this image asset
            color: .orange
        ),
        OnboardingPage(
            title: "Ask Smart Questions",
            subtitle: "Get instant answers about dishes, prices, and restaurant insights",
            imageName: "ask_questions_illustration", // You'll need to add this image asset
            color: .red
        ),
        OnboardingPage(
            title: "Get Deep Insights",
            subtitle: "Discover dish margins, ingredients, and cost breakdowns with AI analysis",
            imageName: "deep_insights_illustration", // You'll need to add this image asset
            color: .blue
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            HStack(spacing: 8) {
                ForEach(0..<onboardingData.count, id: \.self) { index in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(index == currentPage ? .orange : .gray.opacity(0.3))
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.top, 50)
            .padding(.bottom, 30)
            
            // Main Content - Swipeable TabView
            TabView(selection: $currentPage) {
                ForEach(Array(onboardingData.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Bottom Controls
            VStack(spacing: 20) {
                // Skip Button (only on first two pages)
                if currentPage < onboardingData.count - 1 {
                    HStack {
                        Button("Skip") {
                            print("🔄 OnboardingView: User skipped onboarding")
                            onComplete()
                        }
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Get Started Button (final page)
                    Button(action: {
                        print("🎯 OnboardingView: User completed onboarding")
                        onComplete()
                    }) {
                        HStack {
                            Text("Get Started")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
            }
            .padding(.bottom, 50)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Individual Onboarding Page
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Illustration Placeholder
            // TODO: Replace with actual custom illustrations
            IllustrationPlaceholder(
                title: page.title,
                color: page.color
            )
            
            // Text Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(page.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Illustration Placeholder
// Replace this with actual illustrations once they're created
struct IllustrationPlaceholder: View {
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            // Main illustration area
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.1))
                .frame(width: 280, height: 200)
                .overlay(
                    VStack(spacing: 12) {
                        // Icon based on the screen
                        Group {
                            if title.contains("Scan") {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 40))
                                    .foregroundColor(color)
                                    .overlay(
                                        // OCR-style highlights
                                        VStack(spacing: 4) {
                                            Rectangle()
                                                .frame(width: 60, height: 2)
                                                .foregroundColor(.orange.opacity(0.6))
                                            Rectangle()
                                                .frame(width: 45, height: 2)
                                                .foregroundColor(.orange.opacity(0.6))
                                        }
                                        .offset(y: 30)
                                    )
                            } else if title.contains("Ask") {
                                HStack(spacing: 8) {
                                    Image(systemName: "bubble.left.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.blue)
                                    
                                    // Floating food icons
                                    VStack(spacing: 4) {
                                        Image(systemName: "fork.knife")
                                            .font(.system(size: 16))
                                            .foregroundColor(.orange)
                                        Image(systemName: "cup.and.saucer.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red)
                                    }
                                }
                            } else {
                                // Deep Insights - Charts and analysis
                                VStack(spacing: 8) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 35))
                                        .foregroundColor(.blue)
                                    
                                    // Price tags and percentages
                                    HStack(spacing: 8) {
                                        Text("$12")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.green.opacity(0.2))
                                            .cornerRadius(4)
                                        
                                        Text("85%")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.orange.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        
                        Text("Custom Illustration\nWill Go Here")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                )
        }
    }
}

// MARK: - Data Models
struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let color: Color
}

// MARK: - Help Button for Profile
struct HelpButton: View {
    @State private var showingOnboarding = false
    
    var body: some View {
        Button(action: {
            print("📚 HelpButton: Showing onboarding help")
            showingOnboarding = true
        }) {
            Image(systemName: "questionmark.circle")
                .font(.title3)
                .foregroundColor(.orange)
        }
        .sheet(isPresented: $showingOnboarding) {
            NavigationView {
                OnboardingView {
                    showingOnboarding = false
                }
                .navigationTitle("How it Works")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingOnboarding = false
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}

#Preview("Help Button") {
    NavigationView {
        HelpButton()
    }
}
