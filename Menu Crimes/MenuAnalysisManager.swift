//
//  MenuAnalysisManager.swift
//  Menu Crimes
//
//  Created by Roosh on 6/25/25.
//

import Foundation
import UIKit
import Supabase

/// Response model for menu analysis from OpenAI
struct MenuAnalysisResponse: Codable {
    let success: Bool
    let analysis: AnalysisData
    let dishes_found: Int
}

struct AnalysisData: Codable {
    let dishes: [DishAnalysis]
    let overall_notes: String
}


enum MenuAnalysisState {
    case idle
    case uploading
    case analyzing
    case completed(MenuAnalysisResponse)
    case error(String)
}

@Observable
final class MenuAnalysisManager {
    
    private let supabaseClient = supabase
    
    var analysisState: MenuAnalysisState = .idle
    
    init() {
        print("🔍 MenuAnalysisManager: Initialized")
    }
    
    /// Analyze a menu photo using the Supabase edge function
    func analyzeMenu(image: UIImage, currentUser: UserProfile) async {
        print("🔍 MenuAnalysisManager: Starting menu analysis...")
        analysisState = .uploading
        
        do {
            // First upload the image to get a public URL
            let imageUrl = try await uploadImageForAnalysis(image: image, currentUser: currentUser)
            print("🔍 MenuAnalysisManager: Image uploaded successfully to \(imageUrl)")
            
            analysisState = .analyzing
            
            // Call the Supabase edge function
            let response = try await callAnalysisFunction(imageUrl: imageUrl)
            print("🔍 MenuAnalysisManager: Analysis completed successfully")
            print("🔍 MenuAnalysisManager: Response data: \(response)")
            
            analysisState = .completed(response)
            
        } catch {
            print("❌ MenuAnalysisManager: Analysis failed with error: \(error)")
            analysisState = .error("Analysis failed: \(error.localizedDescription)")
        }
    }
    
    /// Upload image to Supabase Storage for analysis
    private func uploadImageForAnalysis(image: UIImage, currentUser: UserProfile) async throws -> String {
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "MenuAnalysisManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Generate unique filename for analysis
        let filename = "analysis/\(UUID().uuidString).jpg"
        
        print("🔍 MenuAnalysisManager: Uploading to bucket 'menu-crimes-photos' with filename: \(filename)")
        
        // Upload to Supabase Storage
        try await supabaseClient.storage
            .from("menu-crimes-photos")
            .upload(path: filename, file: imageData, options: .init(contentType: "image/jpeg"))
        
        // Get public URL
        let publicURL = try supabaseClient.storage
            .from("menu-crimes-photos")
            .getPublicURL(path: filename)
        
        return publicURL.absoluteString
    }
    
    /// Call the Supabase edge function for menu analysis
    private func callAnalysisFunction(imageUrl: String) async throws -> MenuAnalysisResponse {
        print("🔍 MenuAnalysisManager: Calling edge function with image URL: \(imageUrl)")
        
        // Prepare the request body as a properly encodable struct
        struct AnalysisRequest: Codable {
            let image_url: String
            let story_id: String?
        }
        
        let requestBody = AnalysisRequest(
            image_url: imageUrl,
            story_id: nil
        )
        
        // Call the edge function
        let response: MenuAnalysisResponse = try await supabaseClient.functions
            .invoke("anaylze-menu", options: .init(body: requestBody))
        
        return response
    }
    
    /// Reset analysis state
    func resetAnalysisState() {
        print("🔍 MenuAnalysisManager: Resetting analysis state")
        analysisState = .idle
    }
}
