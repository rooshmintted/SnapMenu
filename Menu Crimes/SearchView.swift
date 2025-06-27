//
//  SearchView.swift
//  Menu Crimes
//
//  Premium AI-powered restaurant search interface
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var currentExampleIndex = 0
    @State private var messages: [SearchMessage] = []
    @State private var isLoading = false
    @State private var showingExamples = true
    @State private var showingQuestionPopup = false
    
    // AI Search Manager
    @State var searchAIManager = SearchAIManager()
    
    // Rotating example questions and explanations
    private let exampleQuestions: [(question: String, explanation: String)] = [
        (
            "Which restaurants write their menu like they've read poetry?",
            "Looks for menus using metaphors, rhythm, or lyrical phrasing — not keywords."
        ),
        (
            "Where can I get a meal that feels like a breakup?",
            "Interprets emotional tone: melancholic descriptions, solo-portioned comfort food, sad humor."
        ),
        (
            "Find a menu where the chef is clearly overcompensating.",
            "Looks for exaggerated language, unnecessary luxury ingredients, or desperate bragging."
        ),
        (
            "What places serve food combinations that sound like dares?",
            "Detects absurd or jarring pairings: wasabi ice cream, bacon milkshakes, squid nachos."
        ),
        (
            "Which menus feel like they were written while drunk?",
            "Searches for chaotic structure, typos, over-the-top slang, or incoherent humor."
        ),
        (
            "Where can I eat something that might start a fight at the table?",
            "Flags highly polarizing foods: pineapple pizza, durian desserts, bone marrow shots."
        ),
        (
            "Find me a restaurant that would impress my therapist.",
            "Implies emotional maturity, thoughtful sourcing, gentle food, balanced portions."
        ),
        (
            "Which places have menus that would make Gordon Ramsay yell?",
            "Searches for poor technique descriptions or questionable ingredient combinations."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Main Content
            ZStack {
                if messages.isEmpty && !isLoading {
                    // Welcome State
                    welcomeView
                } else {
                    // Chat Messages
                    messagesView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Search Input
            searchInputView
        }
        .background(Color(.systemBackground))
        .onAppear {
            startExampleRotation()
        }
        .sheet(isPresented: $showingQuestionPopup) {
            ExampleQuestionsPopupView(
                exampleQuestions: exampleQuestions,
                onQuestionSelected: { question in
                    print("💬 SearchView: Selected question from popup: \(question)")
                    searchText = question
                    showingQuestionPopup = false
                }
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Menu AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Discover restaurants with intelligence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Menu AI Icon - Clickable to show example questions
                Button(action: {
                    print("🧠 SearchView: Brain icon tapped, showing question popup")
                    showingQuestionPopup = true
                }) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.white)
                                .font(.title3)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Divider()
                .background(Color(.separator))
        }
        .background(Color(.systemBackground).opacity(0.95))
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                
                // Hero Section
                VStack(spacing: 16) {
                    Text("Ask anything about restaurants")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text("Search menus with natural language. Find dishes, analyze pricing, discover hidden gems.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                
                // Example Questions
                VStack(spacing: 12) {
                    Text("Try asking:")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if showingExamples {
                        ExampleQuestionCard(
                            question: exampleQuestions[currentExampleIndex].question,
                            explanation: exampleQuestions[currentExampleIndex].explanation
                        ) {
                            searchText = exampleQuestions[currentExampleIndex].question
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Messages View
    private var messagesView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    ForEach(messages) { message in
                        if message.isUser {
                            UserMessageBubble(message: message)
                                .id(message.id)
                        } else {
                            AIResponseCard(message: message)
                                .id(message.id)
                        }
                    }
                    
                    // Typing Indicator
                    if isLoading {
                        TypingIndicatorCard()
                            .id("typing")
                    }
                    
                    // Bottom spacing for input
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .onChange(of: messages.count) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    if let lastMessage = messages.last {
                        scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isLoading) { loading in
                if loading {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollProxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Input View
    private var searchInputView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(.separator))
            
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Ask about restaurants, dishes, or menus...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .orange)
                }
                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Functions
    private func startExampleRotation() {
        // Debug: Starting example question rotation with smoother timing
        print("🔄 SearchView: Starting example question rotation with 6-second intervals")
        
        Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            // Slower, gentler fade out animation
            withAnimation(.easeInOut(duration: 0.8)) {
                showingExamples = false
            }
            
            // Longer delay for smoother transition between cards
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                currentExampleIndex = (currentExampleIndex + 1) % exampleQuestions.count
                print("🔄 SearchView: Showing example question \(currentExampleIndex + 1) of \(exampleQuestions.count)")
                
                // Slower, gentler fade in animation  
                withAnimation(.easeInOut(duration: 0.8)) {
                    showingExamples = true
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = SearchMessage(
            id: UUID(),
            content: searchText,
            isUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        
        let query = searchText
        searchText = ""
        isLoading = true
        
        print("🔍 SearchView: Sending search query: \(query)")
        
        // Call AI search function
        Task {
            await searchAIManager.searchMenus(query: query)
            
            // Handle response based on search state
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch self.searchAIManager.searchState {
                case .completed(let response):
                    let responseMessage = SearchMessage(
                        id: UUID(),
                        content: response.answer,
                        isUser: false,
                        timestamp: Date(),
                        sources: response.sources
                    )
                    self.messages.append(responseMessage)
                    
                case .error(let errorMessage):
                    let errorResponseMessage = SearchMessage(
                        id: UUID(),
                        content: "I'm having trouble searching right now. Please try again in a moment.",
                        isUser: false,
                        timestamp: Date(),
                        isError: true
                    )
                    self.messages.append(errorResponseMessage)
                    print("🔍 SearchView Error: \(errorMessage)")
                    
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ExampleQuestionCard: View {
    let question: String
    let explanation: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Text(question)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UserMessageBubble: View {
    let message: SearchMessage
    
    var body: some View {
        HStack {
            Spacer(minLength: 50)
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AIResponseCard: View {
    let message: SearchMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Avatar
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 12) {
                // Response Content
                if message.isError {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(16)
                        .background(Color(.systemRed).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Sources Section
                if let sources = message.sources, !sources.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sources")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        ForEach(Array(sources.prefix(3).enumerated()), id: \.offset) { index, source in
                            SourceCard(source: source, index: index + 1)
                        }
                    }
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 20)
        }
    }
}

struct SourceCard: View {
    let source: SearchSource
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.orange))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(source.restaurant)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text(source.text)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let price = source.price {
                    Text(price)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TypingIndicatorCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("Menu AI is thinking")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    TypingIndicator()
                }
                .padding(16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer(minLength: 20)
        }
    }
}

// MARK: - Search Message Model
struct SearchMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var sources: [SearchSource]?
    var isError: Bool = false
}

// MARK: - Typing Indicator Component
struct TypingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 1)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
            
            Circle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 1)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.2), value: isAnimating)
            
            Circle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 1)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.4), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Example Questions Popup View
struct ExampleQuestionsPopupView: View {
    let exampleQuestions: [(question: String, explanation: String)]
    let onQuestionSelected: (String) -> Void
    
    @State private var currentExampleIndex = 0
    @State private var showingExamples = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Example Questions")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Tap any question to try it")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Menu AI Icon
                        Circle()
                            .fill(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.white)
                                    .font(.title3)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    Divider()
                        .background(Color(.separator))
                }
                .background(Color(.systemBackground).opacity(0.95))
                
                // Main Content - Scrollable list of all example questions
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        Spacer(minLength: 20)
                        
                        // Hero Section
                        VStack(spacing: 16) {
                            Text("Ask anything about restaurants")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("From poetic menus to emotional dining, discover restaurants that match your vibe")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        
                        // All Example Questions
                        VStack(spacing: 16) {
                            Text("Try asking:")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            ForEach(Array(exampleQuestions.enumerated()), id: \.offset) { index, example in
                                ExampleQuestionCard(
                                    question: example.question,
                                    explanation: example.explanation
                                ) {
                                    print("💬 ExampleQuestionsPopupView: Question \(index + 1) selected")
                                    onQuestionSelected(example.question)
                                }
                                .animation(.easeInOut(duration: 0.2), value: example.question)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("✅ ExampleQuestionsPopupView: Dismissed via Done button")
                        dismiss()
                    }
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}
