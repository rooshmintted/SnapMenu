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
    let currentUser: UserProfile
    
    @Environment(\.dismiss) private var dismiss
    
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
                                    
                                    // Overall notes
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Analysis Summary")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text(response.analysis.overall_notes)
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
                                    }
                                    
                                    // Analyzed dishes
                                    if !response.analysis.dishes.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Dish Analysis")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            
                                            ForEach(response.analysis.dishes.indices, id: \.self) { index in
                                                let dish = response.analysis.dishes[index]
                                                DishAnalysisCard(dish: dish)
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
            .navigationTitle("Menu Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        print("📊 MenuAnalysisResultView: Done button tapped")
                        menuAnalysisManager.resetAnalysisState()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            print("📊 MenuAnalysisResultView: View appeared, starting analysis")
            Task {
                await menuAnalysisManager.analyzeMenu(image: image, currentUser: currentUser)
            }
        }
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
        if margin >= 70 {
            return .green
        } else if margin >= 50 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    MenuAnalysisResultView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        menuAnalysisManager: MenuAnalysisManager(),
        currentUser: UserProfile(
            id: UUID(),
            username: "testuser",
            avatarUrl: nil,
            website: nil,
            updatedAt: Date()
        )
    )
}
