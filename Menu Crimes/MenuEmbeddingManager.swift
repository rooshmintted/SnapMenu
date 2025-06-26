//
//  MenuEmbeddingManager.swift
//  Menu Crimes
//
//  Manager for extracting text from menu images, chunking it, and sending to embed-menu edge function
//

import Foundation
import UIKit
import Vision
import Supabase

// MARK: - Menu Text Processing Models

/// Detected text with position information from Vision Framework
struct MenuTextRegion {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
    let yPosition: CGFloat // For sorting by vertical position
}

/// Enhanced chunk format with restaurant name for embed-menu edge function
struct MenuChunk: Codable {
    let text: String
    let section: String
    let restaurant: String
    let timestamp: String
    let cleanedText: String // Store cleaned version for better embeddings
    let originalText: String // Keep original for debugging
    
    enum CodingKeys: String, CodingKey {
        case text, section, restaurant, timestamp, cleanedText, originalText
    }
}

/// Simplified chunk format for embed-menu edge function
struct EmbedMenuResponse: Codable {
    let success: Bool?
    let count: Int?
    let error: String?
    let details: String?
    
    // Computed property for backward compatibility
    var chunksProcessed: Int {
        return count ?? 0
    }
    
    // Computed property for backward compatibility  
    var message: String {
        if let error = error {
            return error
        }
        return success == true ? "Successfully processed chunks" : "Processing failed"
    }
    
    enum CodingKeys: String, CodingKey {
        case success, count, error, details
    }
}

// MARK: - Embedding Processing State
enum EmbeddingState {
    case idle
    case extractingText
    case chunkingText
    case uploadingEmbeddings
    case completed(EmbedMenuResponse)
    case error(String)
}

// MARK: - Menu Embedding Manager
@Observable
final class MenuEmbeddingManager {
    
    private let supabaseClient = supabase
    
    var embeddingState: EmbeddingState = .idle
    var restaurantName: String = "" // Store restaurant name for chunking
    
    init() {
        print("🧠 MenuEmbeddingManager: Initialized")
    }
    
    /// Set restaurant name for embedding chunks
    func setRestaurantName(_ name: String) {
        restaurantName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🧠 MenuEmbeddingManager: Set restaurant name to '\(restaurantName)'")
    }
    
    /// Build chunks from menu analysis response instead of OCR extraction
    /// This uses the structured dish data from the analysis API for cleaner embeddings
    func processMenuForEmbedding(analysisResponse: MenuAnalysisResponse, restaurantName: String, currentUser: UserProfile) async {
        print("🧠 MenuEmbeddingManager: Starting embedding process from analysis response...")
        embeddingState = .chunkingText
        
        do {
            // Build chunks from analysis response dishes
            let chunks = buildMenuChunks(from: analysisResponse, restaurantName: restaurantName)
            print("🧠 MenuEmbeddingManager: Built \(chunks.count) chunks from analysis response")
            
            // Step 2: Send chunks to embed-menu edge function
            embeddingState = .uploadingEmbeddings
            let response = try await sendChunksToEmbedFunction(chunks: chunks)
            
            print("🧠 MenuEmbeddingManager: Embedding completed successfully")
            embeddingState = .completed(response)
            
        } catch {
            print("❌ MenuEmbeddingManager: Embedding process failed: \(error)")
            embeddingState = .error("Embedding failed: \(error.localizedDescription)")
        }
    }
    
    /// Build menu chunks from analysis response
    /// Uses structured dish data for cleaner, more consistent embeddings
    private func buildMenuChunks(from response: MenuAnalysisResponse, restaurantName: String) -> [MenuChunk] {
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        
        print("🧠 MenuEmbeddingManager: Building chunks for \(response.analysis.dishes.count) dishes")
        
        return response.analysis.dishes.map { dish in
            // Create rich text representation with dish name, price, and ingredients
            let text = "\(dish.dishName) – \(dish.price) – \(dish.ingredients)"
            
            // Try to infer section from dish name or use general category
            let section = inferDishSection(from: dish.dishName) ?? "Menu Items"
            
            print("🧠 MenuEmbeddingManager: Created chunk for '\(dish.dishName)' with ingredients: '\(dish.ingredients)' in section '\(section)'")
            
            return MenuChunk(
                text: text,
                section: section,
                restaurant: restaurantName,
                timestamp: now,
                cleanedText: text, // Already clean from analysis
                originalText: text // Same as text since it's from structured data
            )
        }
    }
    
    /// Infer dish section from dish name using keywords
    /// Returns nil if no clear section can be determined
    private func inferDishSection(from dishName: String) -> String? {
        let name = dishName.lowercased()
        
        // Appetizer keywords
        if name.contains("app") || name.contains("starter") || name.contains("wing") || 
           name.contains("nachos") || name.contains("dip") || name.contains("bruschetta") ||
           name.contains("calamari") || name.contains("shrimp") {
            return "Appetizers"
        }
        
        // Dessert keywords
        if name.contains("dessert") || name.contains("cake") || name.contains("ice cream") ||
           name.contains("pie") || name.contains("cookie") || name.contains("brownie") ||
           name.contains("sundae") || name.contains("cheesecake") {
            return "Desserts"
        }
        
        // Beverage keywords
        if name.contains("drink") || name.contains("soda") || name.contains("juice") ||
           name.contains("coffee") || name.contains("tea") || name.contains("beer") ||
           name.contains("wine") || name.contains("cocktail") || name.contains("smoothie") {
            return "Beverages"
        }
        
        // Salad keywords
        if name.contains("salad") || name.contains("greens") {
            return "Salads"
        }
        
        // Sandwich keywords
        if name.contains("sandwich") || name.contains("burger") || name.contains("wrap") ||
           name.contains("panini") || name.contains("sub") {
            return "Sandwiches"
        }
        
        // Default to entrees for most items
        return "Entrees"
    }
    
    /// Send chunks to embed-menu edge function
    private func sendChunksToEmbedFunction(chunks: [MenuChunk]) async throws -> EmbedMenuResponse {
        print("🧠 MenuEmbeddingManager: Sending \(chunks.count) chunks to embed-menu edge function")
        
        do {
            print("🧠 MenuEmbeddingManager: Invoking 'embed-menu' edge function...")
            
            let response: EmbedMenuResponse = try await supabaseClient.functions
                .invoke("embed-menu", options: .init(body: chunks))
            
            print("🧠 MenuEmbeddingManager: Edge function returned successfully")
            
            // Check if the response indicates an error
            if let error = response.error {
                print("❌ MenuEmbeddingManager: Edge function returned error: \(error)")
                if let details = response.details {
                    print("❌ MenuEmbeddingManager: Error details: \(details)")
                }
                throw NSError(domain: "MenuEmbeddingManager", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
            }
            
            print("🧠 MenuEmbeddingManager: Processed \(response.chunksProcessed) chunks")
            return response
            
        } catch {
            print("❌ MenuEmbeddingManager: Supabase functions call failed: \(error)")
            
            // Try direct HTTP call as fallback
            print("🧠 MenuEmbeddingManager: Attempting direct HTTP call as fallback...")
            return try await callEmbedFunctionDirect(request: chunks)
        }
    }
    
    /// Direct HTTP call to embed-menu edge function as fallback
    private func callEmbedFunctionDirect(request: [MenuChunk]) async throws -> EmbedMenuResponse {
        guard let url = URL(string: "https://bepoadtvabwmjxlmlecv.supabase.co/functions/v1/embed-menu") else {
            throw NSError(domain: "MenuEmbeddingManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlcG9hZHR2YWJ3bWp4bG1sZWN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3NzgwNDEsImV4cCI6MjA2NjM1NDA0MX0.7HXHBVx90fgBfwDidZrrAE4SUcOSq0W1BUTQCPyrsJQ", forHTTPHeaderField: "Authorization")
        
        // Encode the array of chunks directly as JSON
        httpRequest.httpBody = try JSONEncoder().encode(request)
        
        print("🧠 MenuEmbeddingManager: Direct HTTP call to: \(url)")
        print("🧠 MenuEmbeddingManager: Sending \(request.count) chunks in array format")
        
        let (data, response) = try await URLSession.shared.data(for: httpRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🧠 MenuEmbeddingManager: Direct HTTP response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ MenuEmbeddingManager: Direct HTTP error response: \(errorString)")
                throw NSError(domain: "MenuEmbeddingManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorString)"])
            }
        }
        
        let embedResponse = try JSONDecoder().decode(EmbedMenuResponse.self, from: data)
        
        // Check if the response indicates an error
        if let error = embedResponse.error {
            print("❌ MenuEmbeddingManager: Edge function returned error: \(error)")
            if let details = embedResponse.details {
                print("❌ MenuEmbeddingManager: Error details: \(details)")
            }
            throw NSError(domain: "MenuEmbeddingManager", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
        }
        
        print("🧠 MenuEmbeddingManager: Direct HTTP call successful")
        print("🧠 MenuEmbeddingManager: Processed \(embedResponse.chunksProcessed) chunks")
        return embedResponse
    }
    
    /// Reset embedding state
    func resetEmbeddingState() {
        print("🧠 MenuEmbeddingManager: Resetting embedding state")
        embeddingState = .idle
    }
}

// MARK: - Helper Structures

/// Represents a logical section of the menu
private struct MenuSection {
    let name: String
    var texts: [String]
    var confidences: [Float]
}
