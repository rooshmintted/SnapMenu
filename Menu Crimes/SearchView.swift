//
//  SearchView.swift
//  Menu Crimes
//
//  ChatGPT-style search interface with rotating example previews
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var currentExampleIndex = 0
    @State private var messages: [SearchMessage] = []
    @State private var isLoading = false
    
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
            "Finds pretentious wording, overdone formatting, or ridiculous item names."
        ),
        (
            "Where can I get dinner and existential dread for under $30?",
            "Combines dark-humored menus, dim ambiance, and dishes like \"Absinthe-glazed marrow.\""
        ),
        (
            "Which restaurants are probably a front for something else?",
            "Looks for suspiciously vague menus, wildly inconsistent pricing, or oddly generic names."
        ),
        (
            "Which Italian restaurants near me serve both gluten-free pasta and tiramisu under $20?",
            "Requires parsing specific dish names, dietary tags, prices, and local context from menus."
        ),
        (
            "Find restaurants with a kid's menu that doesn't have just chicken nuggets and fries.",
            "Needs understanding of \"just nuggets and fries\" as a category exclusion, not a keyword."
        ),
        (
            "Which sushi places offer omakase but don't mention market price?",
            "Involves identifying omakase mentions and filtering based on pricing language."
        ),
        (
            "What's the most unique dessert offered across all Thai restaurants in Manhattan?",
            "Requires comparing dessert menus and detecting unusual or uncommon items."
        ),
        (
            "Which places serve brunch all day but don't say it explicitly?",
            "Needs semantic interpretation of brunch hours, implied availability."
        ),
        (
            "List restaurants that describe their food with humor or personality on the menu.",
            "Looks for tone/style, like \"Bacon that slaps harder than your ex.\""
        ),
        (
            "Where can I get spicy vegetarian food that isn't Indian or Mexican?",
            "Requires dish-level cuisine detection and spice/vegetarian filtering."
        ),
        (
            "Find places that list both French onion soup and Philly cheesesteaks.",
            "Combines two rare pairings, possibly across cuisines, unlikely to be found with keyword search."
        ),
        (
            "Which restaurants mention sustainability or local sourcing directly in their menu descriptions?",
            "Needs sentence-level inference from menu copy, not just site tags."
        ),
        (
            "Are there restaurants where drinks cost more than any of the food items?",
            "Requires numerical comparison of prices across menu sections."
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages Area
                if messages.isEmpty {
                    emptyStateView
                } else {
                    messagesView
                }
                
                Spacer()
                
                // Input Area
                inputArea
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.black)
            .onAppear {
                print("🔍 SearchView: Appeared, starting example rotation")
                startExampleRotation()
            }
        }
    }
    
    // MARK: - Empty State with Rotating Examples
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App branding
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("Menu Crimes Search")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Ask questions about menus the way you actually think")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Rotating Example Preview
                rotatingExampleView
                
                // Getting Started Instructions
                VStack(spacing: 12) {
                    Text("Getting Started")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Try asking about restaurants in natural language. Search for vibes, emotions, or specific food combinations.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 100) // Extra space for input area
            }
        }
    }
    
    // MARK: - Rotating Example View
    private var rotatingExampleView: some View {
        VStack(spacing: 16) {
            // Example indicator dots
            HStack(spacing: 8) {
                ForEach(0..<min(5, exampleQuestions.count), id: \.self) { index in
                    Circle()
                        .fill(index == (currentExampleIndex % 5) ? Color.orange : Color.gray)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentExampleIndex)
                }
            }
            .padding(.bottom, 8)
            
            // Example card
            VStack(alignment: .leading, spacing: 12) {
                Text(exampleQuestions[currentExampleIndex].question)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Text(exampleQuestions[currentExampleIndex].explanation)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            .animation(.easeInOut(duration: 0.5), value: currentExampleIndex)
            .onTapGesture {
                // Tap to use this example
                searchText = exampleQuestions[currentExampleIndex].question
                print("🔍 SearchView: Selected example question: \(searchText)")
            }
        }
    }
    
    // MARK: - Messages View
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(messages) { message in
                    MessageBubble(message: message)
                }
                
                // Show typing indicator when loading
                if isLoading {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("Menu AI is thinking")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                TypingIndicator()
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Spacer()
                    }
                }
                
                if !messages.isEmpty {
                    HStack {
                        Spacer()
                        Text("Powered by OpenAI & Menu Crimes Database")
                            .font(.caption)
                    }
                    .padding()
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 12) {
            // Rotating preview above input (condensed version)
            if messages.isEmpty {
                HStack {
                    Text("Try: ")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(exampleQuestions[currentExampleIndex].question)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .animation(.easeInOut(duration: 0.3), value: currentExampleIndex)
                        .onTapGesture {
                            searchText = exampleQuestions[currentExampleIndex].question
                        }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Input field
            HStack(spacing: 12) {
                TextField("Ask about restaurants...", text: $searchText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.2))
                    )
                    .foregroundColor(.white)
                    .lineLimit(1...4)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(searchText.isEmpty ? .gray : .orange)
                }
                .disabled(searchText.isEmpty || isLoading)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.95))
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Actions
    private func startExampleRotation() {
        // Rotate examples every 4 seconds
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentExampleIndex = (currentExampleIndex + 1) % exampleQuestions.count
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
                        timestamp: Date()
                    )
                    self.messages.append(responseMessage)
                    
                    // Add sources if available
                    if !response.sources.isEmpty {
                        let sourcesText = "Sources:\n" + response.sources.prefix(3).map { source in
                            "• \(source.restaurant) - \(source.text)"
                        }.joined(separator: "\n")
                        
                        let sourcesMessage = SearchMessage(
                            id: UUID(),
                            content: sourcesText,
                            isUser: false,
                            timestamp: Date()
                        )
                        self.messages.append(sourcesMessage)
                    }
                    
                case .error(let errorMessage):
                    let errorResponseMessage = SearchMessage(
                        id: UUID(),
                        content: "Sorry, I encountered an error while searching: \(errorMessage)",
                        isUser: false,
                        timestamp: Date()
                    )
                    self.messages.append(errorResponseMessage)
                    
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Search Message Model
struct SearchMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let message: SearchMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
    }
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

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}
