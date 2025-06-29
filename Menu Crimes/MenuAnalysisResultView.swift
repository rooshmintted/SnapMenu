//
//  MenuAnalysisResultView.swift
//  Menu Crimes
//
//  Created by Roosh on 6/25/25.
//

import SwiftUI

struct MenuAnalysisResultView: View {
    let image: UIImage
    let menuAnalysisManager: MenuAnalysisManager
    let menuAnnotationManager: MenuAnnotationManager
    let currentUser: UserProfile
    let onDone: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Dish Selection State
    @State private var selectedDishes: Set<UUID> = []
    @State private var showingAnnotation = false
    @State private var generatedAnnotations: UIImage?
    @State private var isLoadingAnnotations = false
    @State private var showingShareSheet = false
    
    // MARK: - Restaurant Name State
    @State private var restaurantName: String = ""
    @State private var showingRestaurantInput = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Image preview
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Restaurant Name Input Section
                        if case .completed(_) = menuAnalysisManager.analysisState {
                            RestaurantNameInputView(
                                restaurantName: $restaurantName,
                                onRestaurantNameSet: { name in
                                    // Set restaurant name in embedding manager
                                    if let embeddingManager = menuAnalysisManager.embeddingManager {
                                        embeddingManager.setRestaurantName(name)
                                        print("📊 MenuAnalysisResultView: Set restaurant name for embeddings: '\(name)'")
                                    }
                                }
                            )
                        }
                        
                        // Embedding Process Status (parallel to analysis)
                        if let embeddingManager = menuAnalysisManager.embeddingManager {
                            EmbeddingStatusView(embeddingManager: embeddingManager)
                        }
                        
                        // Analysis content based on state
                        switch menuAnalysisManager.analysisState {
                        case .idle:
                            Text("Ready to analyze")
                                .foregroundColor(.white)
                            
                        case .uploading:
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("Uploading image...")
                                    .foregroundColor(.white)
                                    .font(.title3)
                            }
                            .padding()
                            
                        case .analyzing:
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("AI is analyzing your menu...")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                
                                Text("This may take a few moments")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding()
                            
                        case .completed(let response):
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    // Header with analysis summary
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Menu Analysis Results")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("Found \(response.dishes_found) dishes")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Premium Analysis Summary
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.orange)
                                            
                                            Text("AI Analysis Summary")
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text(response.analysis.overall_notes)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .padding(16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.gray.opacity(0.1))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                    }
                                    
                                    // Analyzed dishes with selection
                                    if !response.analysis.dishes.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Dish Analysis")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                if !selectedDishes.isEmpty {
                                                    Text("\(selectedDishes.count) selected")
                                                        .font(.caption)
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            
                                            Text("Select dishes to include in annotation")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            ForEach(response.analysis.dishes.indices, id: \.self) { index in
                                                let dish = response.analysis.dishes[index]
                                                SelectableDishAnalysisCard(
                                                    dish: dish,
                                                    isSelected: selectedDishes.contains(dish.id),
                                                    onSelectionChanged: { isSelected in
                                                        if isSelected {
                                                            selectedDishes.insert(dish.id)
                                                            print("📊 MenuAnalysisResultView: Selected dish '\(dish.dishName)' for annotation")
                                                        } else {
                                                            selectedDishes.remove(dish.id)
                                                            print("📊 MenuAnalysisResultView: Deselected dish '\(dish.dishName)' from annotation")
                                                        }
                                                        print("📊 MenuAnalysisResultView: Total selected dishes: \(selectedDishes.count)")
                                                    }
                                                )
                                            }
                                            
                                            // Premium Annotate Menu button
                                            if !selectedDishes.isEmpty {
                                                Button(action: {
                                                    print("📊 MenuAnalysisResultView: Annotate Menu button tapped with \(selectedDishes.count) selected dishes")
                                                    // Generate annotations directly
                                                    generateAnnotationsDirectly(response: response)
                                                }) {
                                                    HStack(spacing: 12) {
                                                        if isLoadingAnnotations {
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                                .scaleEffect(0.9)
                                                        } else {
                                                            Image(systemName: "wand.and.stars")
                                                                .font(.system(size: 16, weight: .medium))
                                                        }
                                                        Text(isLoadingAnnotations ? "Creating Annotations..." : "Annotate with AI")
                                                            .font(.system(size: 16, weight: .semibold))
                                                    }
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 16)
                                                    .background(
                                                        isLoadingAnnotations ?
                                                        LinearGradient(
                                                            colors: [.gray.opacity(0.8), .gray],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        ) :
                                                        LinearGradient(
                                                            colors: [.orange, .red],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .cornerRadius(16)
                                                }
                                                .disabled(isLoadingAnnotations)
                                                .scaleEffect(isLoadingAnnotations ? 0.98 : 1.0)
                                                .animation(.easeInOut(duration: 0.1), value: isLoadingAnnotations)
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                            
                        case .error(let errorMessage):
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.red)
                                
                                Text("Analysis Failed")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(errorMessage)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("Try Again") {
                                    print("🔍 MenuAnalysisResultView: Retry analysis button tapped")
                                    Task {
                                        await menuAnalysisManager.analyzeMenu(image: image, currentUser: currentUser)
                                    }
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Menu AI Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingAnnotation) {
            if let annotatedImage = generatedAnnotations {
                NavigationView {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        ScrollView([.horizontal, .vertical]) {
                            Image(uiImage: annotatedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding()
                        }
                    }
                    .navigationTitle("Annotated Menu")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(
                        leading: Button("Done") {
                            showingAnnotation = false
                        }
                        .foregroundColor(.white),
                        trailing: Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }
                    )
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(1.5)
                    
                    Text("Generating annotated menu...")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let annotatedImage = generatedAnnotations {
                ActivityViewController(activityItems: [annotatedImage], applicationActivities: nil)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(1.5)
                    
                    Text("Generating annotated menu...")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Prepare annotation data with selected dishes and original image
    private func prepareAnnotationData(response: MenuAnalysisResponse) {
        print("📊 MenuAnalysisResultView: Preparing annotation data for \(selectedDishes.count) selected dishes")
        
        // Filter dishes to only include selected ones
        let selectedDishesArray = response.analysis.dishes.filter { dish in
            selectedDishes.contains(dish.id)
        }
        
        // Create filtered analysis response with only selected dishes
        let filteredAnalysis = AnalysisData(
            dishes: selectedDishesArray,
            overall_notes: response.analysis.overall_notes
        )
        
        let filteredResponse = MenuAnalysisResponse(
            success: response.success,
            analysis: filteredAnalysis,
            dishes_found: selectedDishesArray.count
        )
        
        // Set the filtered data and image in annotation manager
        menuAnnotationManager.setAnalysisData(filteredResponse, image: image)
        
        print("📊 MenuAnalysisResultView: Prepared annotation data with \(selectedDishesArray.count) dishes")
        print("   Selected dishes: \(selectedDishesArray.map { $0.dishName }.joined(separator: ", "))")
    }
    
    /// Get color for score visualization
    private func scoreColor(for score: Double) -> Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func generateAnnotationsDirectly(response: MenuAnalysisResponse) {
        isLoadingAnnotations = true
        generatedAnnotations = nil // Clear previous annotations
        
        // Filter selected dishes
        let selectedDishesArray = response.analysis.dishes.filter { dish in
            selectedDishes.contains(dish.id)
        }
        
        print("📊 MenuAnalysisResultView: Generating annotations for \(selectedDishesArray.count) selected dishes")
        
        Task {
            do {
                // Generate annotations using the manager
                let annotatedImage = await menuAnnotationManager.generateAnnotations(
                    for: selectedDishesArray, 
                    image: image
                )
                
                await MainActor.run {
                    if let annotatedImage = annotatedImage {
                        print("✅ MenuAnalysisResultView: Successfully generated annotated image")
                        generatedAnnotations = annotatedImage
                        showingAnnotation = true
                    } else {
                        print("❌ MenuAnalysisResultView: Failed to generate annotated image")
                        // Could show an error alert here
                    }
                    isLoadingAnnotations = false
                }
            } catch {
                print("❌ MenuAnalysisResultView: Error generating annotations: \(error)")
                await MainActor.run {
                    isLoadingAnnotations = false
                    // Could show an error alert here
                }
            }
        }
    }
}

struct DishAnalysisCard: View {
    let dish: DishAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dish.dishName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(dish.price)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(dish.marginPercentage))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(marginColor(for: Double(dish.marginPercentage)))
                    
                    Text("margin")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Text("Cost: $\(String(format: "%.2f", dish.estimatedFoodCost))")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.2)))
            
            Text(dish.justification)
                .font(.body)
                .foregroundColor(.white)
                .opacity(0.8)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
    }
    
    /// Get color for margin visualization
    private func marginColor(for margin: Double) -> Color {
        if margin >= 75 {
            return .red      // High margins are bad
        } else if margin >= 65 {
            return .orange   // Medium margins
        } else {
            return .green    // Low margins are good
        }
    }
}

struct SelectableDishAnalysisCard: View {
    let dish: DishAnalysis
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.square" : "square")
                .foregroundColor(isSelected ? .blue : .gray)
                .onTapGesture {
                    onSelectionChanged(!isSelected)
                }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dish.dishName)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(dish.price)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(Int(dish.marginPercentage))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(marginColor(for: Double(dish.marginPercentage)))
                        
                        Text("margin")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text("Cost: $\(String(format: "%.2f", dish.estimatedFoodCost))")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.2)))
                
                Text(dish.justification)
                    .font(.body)
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
    }
    
    /// Get color for margin visualization
    private func marginColor(for margin: Double) -> Color {
        if margin >= 75 {
            return .red      // High margins are bad
        } else if margin >= 65 {
            return .orange   // Medium margins
        } else {
            return .green    // Low margins are good
        }
    }
}

// MARK: - Embedding Status View

/// Shows the status of the parallel embedding process
struct EmbeddingStatusView: View {
    let embeddingManager: MenuEmbeddingManager
    
    var body: some View {
        switch embeddingManager.embeddingState {
        case .idle:
            EmptyView() // Don't show anything when idle
            
        case .extractingText:
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Processing menu text...")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Extracting text using AI vision")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
            
        case .chunkingText:
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Organizing menu content...")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Creating sections for smart search")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
            
        case .uploadingEmbeddings:
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Building search database...")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Enabling future AI-powered features")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
            
        case .completed(let response):
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Menu processed for AI search")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Processed \(response.chunksProcessed) sections")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.1)))
            .transition(.opacity.combined(with: .slide))
            
        case .error(let errorMessage):
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Processing incomplete")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Analysis still complete")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
        }
    }
}

// MARK: - Restaurant Name Input View

/// Input field for restaurant name to enhance embedding quality
struct RestaurantNameInputView: View {
    @Binding var restaurantName: String
    let onRestaurantNameSet: (String) -> Void
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "building.2")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text("Restaurant Information")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !restaurantName.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20, weight: .medium))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter restaurant name for better search", text: $restaurantName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        setRestaurantName()
                    }
                    .onChange(of: restaurantName) { _, newValue in
                        if !newValue.isEmpty && !isEditing {
                            // Auto-set after user stops typing for 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                if restaurantName == newValue && !newValue.isEmpty {
                                    setRestaurantName()
                                }
                            }
                        }
                    }
                
                Text("Enhance AI search accuracy by providing restaurant context")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            restaurantName.isEmpty ? 
                            AnyShapeStyle(Color.gray.opacity(0.3)) : 
                            AnyShapeStyle(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )),
                            lineWidth: restaurantName.isEmpty ? 1 : 2
                        )
                )
        )
    }
    
    private func setRestaurantName() {
        let trimmedName = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            onRestaurantNameSet(trimmedName)
            print("🏢 RestaurantNameInputView: Restaurant name set to '\(trimmedName)'")
        }
    }
}

// MARK: - Preview

#Preview {
    MenuAnalysisResultView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        menuAnalysisManager: MenuAnalysisManager(),
        menuAnnotationManager: MenuAnnotationManager(),
        currentUser: UserProfile(
            id: UUID(),
            username: "testuser",
            avatarUrl: nil,
            website: nil,
            updatedAt: Date()
        ),
        onDone: {}
    )
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to do here
    }
}
