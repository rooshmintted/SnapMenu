//
//  MenuAnalysisManager.swift
//  Menu Crimes
//
//  Created by Roosh on 6/25/25.
//

import Foundation
import UIKit
import Supabase

@Observable
final class MenuAnalysisManager {
    
    private let supabaseClient = supabase
    
    var analysisState: MenuAnalysisState = .idle
    var uploadedImageUrl: String? // Store the uploaded image URL for reuse
    
    init() {
        print("🔍 MenuAnalysisManager: Initialized")
    }
    
    /// Analyze a menu photo using the Supabase edge function
    func analyzeMenu(image: UIImage, currentUser: UserProfile) async {
        print("🔍 MenuAnalysisManager: Starting menu analysis...")
        
        do {
            analysisState = .uploading
            let imageUrl = try await uploadImageForAnalysis(image: image, currentUser: currentUser)
            uploadedImageUrl = imageUrl // Store for reuse
            
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
        
        do {
            print("🔍 MenuAnalysisManager: Invoking edge function 'anaylze-menu'...")
            print("🔍 MenuAnalysisManager: Request body: \(requestBody)")
            
            // Call the edge function using Supabase client
            let response: MenuAnalysisResponse = try await supabaseClient.functions
                .invoke("anaylze-menu", options: .init(body: requestBody))
            
            print("🔍 MenuAnalysisManager: Edge function returned successfully")
            return response
            
        } catch {
            print("❌ MenuAnalysisManager: Supabase functions call failed: \(error)")
            
            // Try direct HTTP call as fallback
            print("🔍 MenuAnalysisManager: Attempting direct HTTP call as fallback...")
            return try await callAnalysisFunctionDirect(imageUrl: imageUrl)
        }
    }
    
    /// Direct HTTP call to edge function as fallback
    private func callAnalysisFunctionDirect(imageUrl: String) async throws -> MenuAnalysisResponse {
        guard let url = URL(string: "https://bepoadtvabwmjxlmlecv.supabase.co/functions/v1/anaylze-menu") else {
            throw NSError(domain: "MenuAnalysisManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlcG9hZHR2YWJ3bWp4bG1sZWN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3NzgwNDEsImV4cCI6MjA2NjM1NDA0MX0.7HXHBVx90fgBfwDidZrrAE4SUcOSq0W1BUTQCPyrsJQ", forHTTPHeaderField: "Authorization")
        
        let requestBody = ["image_url": imageUrl, "story_id": nil] as [String: Any?]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔍 MenuAnalysisManager: Direct HTTP call to: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 MenuAnalysisManager: Direct HTTP response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ MenuAnalysisManager: Direct HTTP error response: \(errorString)")
                throw NSError(domain: "MenuAnalysisManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorString)"])
            }
        }
        
        let analysisResponse = try JSONDecoder().decode(MenuAnalysisResponse.self, from: data)
        print("🔍 MenuAnalysisManager: Direct HTTP call successful")
        return analysisResponse
    }
    
    /// Reset analysis state
    func resetAnalysisState() {
        print("🔍 MenuAnalysisManager: Resetting analysis state")
        analysisState = .idle
    }
}
