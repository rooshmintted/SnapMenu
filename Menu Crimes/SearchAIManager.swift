//
//  SearchAIManager.swift
//  Menu Crimes
//
//  AI-powered menu search using RAG (Retrieval Augmented Generation)
//

import Foundation
import Supabase

@Observable
final class SearchAIManager {
    
    private let supabaseClient = supabase
    
    var searchState: SearchState = .idle
    
    init() {
        print("🤖 SearchAIManager: Initialized")
    }
    
    /// Submit a query to the AI search system
    func searchMenus(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ SearchAIManager: Empty query provided")
            return
        }
        
        print("🤖 SearchAIManager: Starting search for query: \(query)")
        
        do {
            searchState = .searching
            
            let response = try await callSearchFunction(query: query)
            print("🤖 SearchAIManager: Search completed successfully")
            searchState = .completed(response)
            
        } catch {
            print("❌ SearchAIManager: Search failed with error: \(error)")
            searchState = .error("Search failed: \(error.localizedDescription)")
        }
    }
    
    /// Call the Supabase edge function for AI search
    private func callSearchFunction(query: String) async throws -> SearchResponse {
        print("🤖 SearchAIManager: Calling edge function 'query-menu' with query: \(query)")
        
        // Prepare the request body as a properly encodable struct
        struct SearchRequest: Codable {
            let query: String
        }
        
        let requestBody = SearchRequest(query: query)
        
        do {
            print("🤖 SearchAIManager: Invoking edge function 'query-menu'...")
            let response: SearchResponse = try await supabaseClient.functions
                .invoke("query-menu", options: .init(body: requestBody))
            
            print("🤖 SearchAIManager: Edge function returned successfully")
            return response
            
        } catch {
            print("❌ SearchAIManager: Supabase functions call failed: \(error)")
            
            // Try direct HTTP call as fallback
            print("🤖 SearchAIManager: Attempting direct HTTP call as fallback...")
            return try await callSearchFunctionDirect(query: query)
        }
    }
    
    /// Direct HTTP call to edge function as fallback
    private func callSearchFunctionDirect(query: String) async throws -> SearchResponse {
        guard let url = URL(string: "https://bepoadtvabwmjxlmlecv.supabase.co/functions/v1/query-menu") else {
            throw NSError(domain: "SearchAIManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlcG9hZHR2YWJ3bWp4bG1sZWN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3NzgwNDEsImV4cCI6MjA2NjM1NDA0MX0.7HXHBVx90fgBfwDidZrrAE4SUcOSq0W1BUTQCPyrsJQ", forHTTPHeaderField: "Authorization")
        
        let requestBody = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🤖 SearchAIManager: Direct HTTP call to: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🤖 SearchAIManager: Direct HTTP response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ SearchAIManager: Direct HTTP error response: \(errorString)")
                throw NSError(domain: "SearchAIManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorString)"])
            }
        }
        
        let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
        print("🤖 SearchAIManager: Direct HTTP call successful")
        return searchResponse
    }
    
    /// Reset search state
    func resetSearchState() {
        print("🤖 SearchAIManager: Resetting search state")
        searchState = .idle
    }
}
