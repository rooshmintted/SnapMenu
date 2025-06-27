//
//  Models.swift
//  Menu Crimes
//
//  Data models for user authentication and menu analysis
//

import Foundation
import Supabase

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let username: String  // Made non-optional as primary display name
    let avatarUrl: String?
    let website: String?   // Exists in your database schema
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarUrl = "avatar_url"
        case website
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
    
    // Hashable conformance - hash based on unique ID
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Authentication State
enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated(UserProfile)
    case error(String)
    
    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
    
    var currentUser: UserProfile? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}

// MARK: - Menu Analysis Models
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

struct DishAnalysis: Codable, Identifiable {
    let id = UUID()
    let dishName: String
    let ingredients: String // New field for embedding purposes
    let marginPercentage: Int
    let justification: String // Keep for UI display
    let coordinates: DishCoordinates? // Optional since we get coordinates from Vision Framework
    let price: String
    let estimatedFoodCost: Double
    
    enum CodingKeys: String, CodingKey {
        case dishName = "dish_name"
        case ingredients // New field
        case marginPercentage = "margin_percentage"
        case justification, coordinates, price
        case estimatedFoodCost = "estimated_food_cost"
    }
}

struct DishCoordinates: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

enum MenuAnalysisState {
    case idle
    case uploading
    case analyzing
    case completed(MenuAnalysisResponse)
    case error(String)
}

// MARK: - Search Models
/// Response model for AI-powered menu search
struct SearchResponse: Codable {
    let answer: String
    let sources: [SearchSource]
}

struct SearchSource: Codable, Identifiable {
    var id: String { "\(restaurant)_\(section)_\(text.hashValue)" }
    let text: String
    let restaurant: String
    let section: String
    let price: String?
}

enum SearchState {
    case idle
    case searching
    case completed(SearchResponse)
    case error(String)
}
