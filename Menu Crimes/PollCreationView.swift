//
//  PollCreationView.swift
//  Menu Crimes
//
//  Created by Roosh on 6/25/25.
//

import SwiftUI
import Supabase

struct PollCreationView: View {
    let analysisResponse: MenuAnalysisResponse
    let menuImage: UIImage
    let pollManager: PollManager
    let friendManager: FriendManager
    let currentUser: UserProfile
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var pollConfig = PollConfiguration()
    @State private var selectedDishes: Set<String> = []
    @State private var selectedFriends: Set<UserProfile> = []
    @State private var menuImageUrl: String = ""
    @State private var isUploading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Media Preview Section
                    MediaPreviewSection(image: menuImage)
                    
                    // MARK: - Analysis Summary Section
                    AnalysisSummarySection(response: analysisResponse)
                    
                    // MARK: - Poll Settings Section
                    PollSettingsSection(config: $pollConfig)
                    
                    // MARK: - Dish Selection Section
                    DishSelectionSection(
                        dishes: analysisResponse.analysis.dishes,
                        selectedDishes: $selectedDishes
                    )
                    
                    // MARK: - Friend Selection Section
                    FriendSelectionSection(
                        friendManager: friendManager,
                        selectedFriends: $selectedFriends,
                        currentUser: currentUser
                    )
                    
                    // MARK: - Create Poll Button
                    CreatePollButton(
                        isEnabled: !selectedDishes.isEmpty && !selectedFriends.isEmpty,
                        isLoading: pollManager.pollState == .creating || isUploading
                    ) {
                        await createPoll()
                    }
                }
                .padding()
            }
            .navigationTitle("Create Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-select all dishes by default
                selectedDishes = Set(analysisResponse.analysis.dishes.map { $0.dishName })
                uploadMenuImage()
            }
            .onChange(of: pollManager.pollState) { _, newState in
                if case .success = newState {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Upload menu image to Supabase Storage for the poll
    private func uploadMenuImage() {
        Task {
            isUploading = true
            print("🗳️ PollCreationView: Uploading menu image...")
            
            do {
                // Generate unique filename
                let filename = "\(UUID().uuidString)_menu.jpg"
                
                // Convert image to data
                guard let imageData = menuImage.jpegData(compressionQuality: 0.8) else {
                    throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
                }
                
                // Upload to Supabase Storage
                try await supabase.storage
                    .from("polls")
                    .upload(
                        path: filename,
                        file: imageData,
                        options: FileOptions(contentType: "image/jpeg")
                    )
                
                // Get public URL
                let publicURL = try supabase.storage
                    .from("polls")
                    .getPublicURL(path: filename)
                
                menuImageUrl = publicURL.absoluteString
                print("🗳️ PollCreationView: Image uploaded successfully: \(menuImageUrl)")
                
            } catch {
                print("❌ PollCreationView: Failed to upload image: \(error)")
                // Use fallback or show error
            }
            
            isUploading = false
        }
    }
    
    /// Create the poll with selected configuration
    private func createPoll() async {
        guard !menuImageUrl.isEmpty else {
            print("❌ PollCreationView: Menu image not uploaded yet")
            return
        }
        
        print("🗳️ PollCreationView: Creating poll with \(selectedDishes.count) dishes and \(selectedFriends.count) friends")
        
        // Update poll options to only include selected dishes
        var updatedConfig = pollConfig
        
        await pollManager.createPoll(
            analysisResponse: analysisResponse,
            menuImageUrl: menuImageUrl,
            configuration: updatedConfig,
            selectedFriends: Array(selectedFriends),
            currentUser: currentUser
        )
    }
}

// MARK: - Media Preview Section
struct MediaPreviewSection: View {
    let image: UIImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Menu Photo")
                .font(.headline)
                .fontWeight(.semibold)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
        }
    }
}

// MARK: - Analysis Summary Section
struct AnalysisSummarySection: View {
    let response: MenuAnalysisResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Found \(response.dishes_found) dishes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(response.analysis.overall_notes)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Poll Settings Section
struct PollSettingsSection: View {
    @Binding var config: PollConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Poll Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Poll Question
            VStack(alignment: .leading, spacing: 4) {
                Text("Question")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Ask your friends...", text: $config.question)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Duration Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Duration")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Duration", selection: $config.duration) {
                    ForEach(PollDuration.allCases, id: \.self) { duration in
                        Text(duration.displayName).tag(duration)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Multiple Votes Toggle
            Toggle("Allow multiple votes per person", isOn: $config.allowMultipleVotes)
                .font(.subheadline)
        }
    }
}

// MARK: - Dish Selection Section
struct DishSelectionSection: View {
    let dishes: [DishAnalysis]
    @Binding var selectedDishes: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Dishes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(selectedDishes.count) of \(dishes.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(dishes) { dish in
                    DishSelectionRow(
                        dish: dish,
                        isSelected: selectedDishes.contains(dish.dishName)
                    ) {
                        toggleDishSelection(dish.dishName)
                    }
                }
            }
        }
    }
    
    private func toggleDishSelection(_ dishName: String) {
        if selectedDishes.contains(dishName) {
            selectedDishes.remove(dishName)
        } else {
            selectedDishes.insert(dishName)
        }
    }
}

// MARK: - Dish Selection Row
struct DishSelectionRow: View {
    let dish: DishAnalysis
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dish.dishName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(dish.price)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Margin indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(marginColor(for: dish.marginPercentage))
                                .frame(width: 8, height: 8)
                            
                            Text("\(dish.marginPercentage)% margin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func marginColor(for percentage: Int) -> Color {
        switch percentage {
        case 0..<30: return .red
        case 30..<60: return .orange
        case 60..<80: return .yellow
        default: return .green
        }
    }
}

// MARK: - Friend Selection Section
struct FriendSelectionSection: View {
    let friendManager: FriendManager
    @Binding var selectedFriends: Set<UserProfile>
    let currentUser: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Friends")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(selectedFriends.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(friendManager.friends) { friend in
                    FriendSelectionRow(
                        friend: friend,
                        isSelected: selectedFriends.contains(friend)
                    ) {
                        toggleFriendSelection(friend)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await friendManager.loadFriends()
            }
        }
    }
    
    private func toggleFriendSelection(_ friend: UserProfile) {
        if selectedFriends.contains(friend) {
            selectedFriends.remove(friend)
        } else {
            selectedFriends.insert(friend)
        }
    }
}

// MARK: - Friend Selection Row
struct FriendSelectionRow: View {
    let friend: UserProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(friend.username)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Poll Button
struct CreatePollButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isLoading ? "Creating Poll..." : "Create Poll")
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEnabled ? Color.blue : Color.gray)
        )
        .foregroundColor(.white)
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Preview
#Preview {
    PollCreationView(
        analysisResponse: MenuAnalysisResponse(
            success: true,
            analysis: AnalysisData(
                dishes: [
                    DishAnalysis(
                        dishName: "Caesar Salad",
                        marginPercentage: 75,
                        justification: "High margin dish",
                        coordinates: nil,
                        price: "$12",
                        estimatedFoodCost: 3.0
                    )
                ],
                overall_notes: "Great menu with high margin dishes"
            ),
            dishes_found: 1
        ),
        menuImage: UIImage(systemName: "photo") ?? UIImage(),
        pollManager: PollManager(),
        friendManager: FriendManager(authManager: AuthManager()),
        currentUser: UserProfile(
            id: UUID(),
            username: "testuser",
            avatarUrl: nil,
            website: nil,
            updatedAt: Date()
        )
    )
}
