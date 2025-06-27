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
// SwiftUI mockups for onboarding illustrations
struct IllustrationPlaceholder: View {
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            // Large SwiftUI mockup area - no background container
            Group {
                if title.contains("Scan") {
                    // Large mock dish analysis card
                    LargeMockDishAnalysisCard()
                } else if title.contains("Ask") {
                    // Large mock rotating questions
                    LargeMockRotatingQuestions()
                } else {
                    // Large mock analysis breakdown
                    LargeMockAnalysisBreakdown()
                }
            }
            .frame(width: 280, height: 180)
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



// MARK: - Large Mock Components for Onboarding

struct LargeMockDishAnalysisCard: View {
    var body: some View {
        VStack(spacing: 12) {
            // Two dish analysis cards
            HStack(spacing: 8) {
                DishCard(name: "Truffle Pasta", price: "$28", margin: 85, cost: 4.20, description: "Premium pasta with minimal truffle oil")
                DishCard(name: "Caesar Salad", price: "$18", margin: 92, cost: 1.44, description: "Simple greens with house dressing")
            }
            
            // Summary stats
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("Avg Margin")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("88%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 2) {
                    Text("Dishes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("12")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 2) {
                    Text("Revenue")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("$1.2K")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

struct DishCard: View {
    let name: String
    let price: String
    let margin: Int
    let cost: Double
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(price)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(margin)%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(margin >= 80 ? .green : margin >= 60 ? .orange : .red)
                    
                    Text("margin")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Cost: $\(String(format: "%.2f", cost))")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.15)))
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
        .frame(maxWidth: 120)
    }
}

struct LargeMockRotatingQuestions: View {
    @State private var currentIndex = 0
    
    private let questions = [
        ("Which restaurants write their menu like they've read poetry?", "Looks for menus using metaphors, rhythm, or lyrical phrasing — not keywords."),
        ("Where can I get a meal that feels like a breakup?", "Interprets emotional tone: melancholic descriptions, solo-portioned comfort food, sad humor."),
        ("Find a menu where the chef is clearly overcompensating.", "Looks for exaggerated language, unnecessary luxury ingredients, or desperate bragging.")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with AI branding
            HStack(spacing: 8) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Menu AI")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Ask me anything about restaurants")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Compact question card
            VStack(alignment: .leading, spacing: 8) {
                Text(questions[currentIndex].0)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .animation(.easeInOut(duration: 0.5), value: currentIndex)
                
                Text(questions[currentIndex].1)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .animation(.easeInOut(duration: 0.5), value: currentIndex)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
            
            // Rotation indicator dots
            HStack(spacing: 6) {
                ForEach(0..<questions.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentIndex = (currentIndex + 1) % questions.count
                }
            }
        }
    }
}

struct LargeMockAnalysisBreakdown: View {
    var body: some View {
        VStack(spacing: 12) {
            // Compact bar chart
            VStack(spacing: 8) {
                Text("Margin Analysis")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach([("Apps", 85), ("Mains", 72), ("Desserts", 90), ("Drinks", 95)], id: \.0) { category, margin in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(LinearGradient(
                                    colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                ))
                                .frame(width: 24, height: CGFloat(margin) * 0.8)
                            
                            Text("\(margin)%")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(height: 100)
            }
            
            // Compact statistics grid
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    VStack(spacing: 2) {
                        Text("Avg Margin")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("85%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.1)))
                    
                    VStack(spacing: 2) {
                        Text("Revenue")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("$2.3K")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.1)))
                }
                
                VStack(spacing: 4) {
                    VStack(spacing: 2) {
                        Text("Best")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Drinks")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.1)))
                    
                    VStack(spacing: 2) {
                        Text("Dishes")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("24")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5)))
                }
            }
        }
    }
}

// MARK: - Small Mock Components for Onboarding

struct MockDishAnalysisCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Truffle Pasta")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("$28")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text("85%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("margin")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Cost: $4.20")
                .font(.caption2)
                .foregroundColor(.blue)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.blue.opacity(0.15)))
            
            Text("Premium pasta with minimal truffle oil")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
        .frame(maxWidth: 140)
    }
}

struct MockRotatingQuestions: View {
    @State private var currentIndex = 0
    
    private let questions = [
        "Which restaurants write menus like poetry?",
        "Find me food that feels like a hug?",
        "Where can I eat something rebellious?"
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "bubble.left.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            
            Text(questions[currentIndex])
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: 120)
                .animation(.easeInOut, value: currentIndex)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentIndex = (currentIndex + 1) % questions.count
                }
            }
        }
    }
}

struct MockAnalysisBreakdown: View {
    var body: some View {
        VStack(spacing: 6) {
            // Chart representation
            HStack(alignment: .bottom, spacing: 3) {
                ForEach([65, 45, 80, 55], id: \.self) { height in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.orange.opacity(0.7))
                        .frame(width: 8, height: CGFloat(height) * 0.4)
                }
            }
            .frame(height: 32)
            
            // Mock statistics
            VStack(spacing: 3) {
                HStack(spacing: 8) {
                    Text("Average: 73%")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text("$18.50")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                Text("12 dishes analyzed")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
        .frame(maxWidth: 120)
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
