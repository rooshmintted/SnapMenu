//
//  StatsManager.swift
//  Menu Crimes
//
//  Manager for tracking and updating user menu analysis statistics
//  Handles Core Data operations for menu submission and dish analysis counts
//

import CoreData
import Foundation

@Observable
final class StatsManager {
    
    private let viewContext: NSManagedObjectContext
    private var currentUserStats: UserStats?
    
    // Published stats for UI binding
    var menusSubmitted: Int32 = 0
    var dishesAnalyzed: Int32 = 0
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        print("📊 StatsManager: Initialized with Core Data context")
    }
    
    /// Load or create user stats for the current user
    func loadUserStats(for userID: String?) async {
        print("📊 StatsManager: Loading stats for user: \(userID ?? "unknown")")
        
        await MainActor.run {
            let request: NSFetchRequest<UserStats> = UserStats.fetchRequest()
            request.predicate = NSPredicate(format: "userID == %@", userID ?? "")
            request.fetchLimit = 1
            
            do {
                let results = try viewContext.fetch(request)
                
                if let existingStats = results.first {
                    // Found existing stats
                    currentUserStats = existingStats
                    menusSubmitted = existingStats.menusSubmitted
                    dishesAnalyzed = existingStats.dishesAnalyzed
                    print("📊 StatsManager: Loaded existing stats - Menus: \(menusSubmitted), Dishes: \(dishesAnalyzed)")
                } else {
                    // Create new stats record
                    let newStats = UserStats(context: viewContext, userID: userID)
                    currentUserStats = newStats
                    menusSubmitted = 0
                    dishesAnalyzed = 0
                    
                    try viewContext.save()
                    print("📊 StatsManager: Created new stats record for user")
                }
            } catch {
                print("❌ StatsManager: Error loading user stats: \(error)")
                // Create fallback stats
                currentUserStats = UserStats(context: viewContext, userID: userID)
                menusSubmitted = 0
                dishesAnalyzed = 0
            }
        }
    }
    
    /// Record a new menu analysis and update statistics
    func recordMenuAnalysis(dishCount: Int, userID: String?) async {
        print("📊 StatsManager: Recording menu analysis with \(dishCount) dishes for user: \(userID ?? "unknown")")
        
        await MainActor.run {
            // Create new analysis record
            let _ = MenuAnalysis(context: viewContext, dishCount: Int32(dishCount), userID: userID)
            
            // Update user stats
            if let stats = currentUserStats {
                stats.menusSubmitted += 1
                stats.dishesAnalyzed += Int32(dishCount)
                stats.lastUpdated = Date()
                
                // Update published properties
                menusSubmitted = stats.menusSubmitted
                dishesAnalyzed = stats.dishesAnalyzed
                
                print("📊 StatsManager: Updated stats - Menus: \(menusSubmitted), Dishes: \(dishesAnalyzed)")
            } else {
                print("❌ StatsManager: No current user stats found to update")
                // Create new stats if somehow missing
                let newStats = UserStats(context: viewContext, userID: userID)
                newStats.menusSubmitted = 1
                newStats.dishesAnalyzed = Int32(dishCount)
                currentUserStats = newStats
                
                menusSubmitted = 1
                dishesAnalyzed = Int32(dishCount)
            }
            
            // Save context
            do {
                try viewContext.save()
                print("📊 StatsManager: Successfully saved menu analysis stats")
            } catch {
                print("❌ StatsManager: Error saving stats: \(error)")
            }
        }
    }
    
    /// Get achievement status based on current stats
    func getAchievementStatus() -> [String: Bool] {
        let achievements = [
            "first_menu": menusSubmitted >= 1,
            "menu_explorer": menusSubmitted >= 10,
            "dish_detective": dishesAnalyzed >= 50,
            "menu_master": menusSubmitted >= 25,
            "culinary_analyst": dishesAnalyzed >= 100,
            "menu_legend": menusSubmitted >= 50
        ]
        
        print("📊 StatsManager: Achievement status calculated: \(achievements)")
        return achievements
    }
    
    /// Get progress toward next milestone (out of 100)
    func getMilestoneProgress() -> (current: Int, target: Int, progress: Double) {
        let milestones = [10, 25, 50, 100, 200]
        let currentCount = Int(menusSubmitted)
        
        // Find next milestone
        var nextMilestone = 10
        for milestone in milestones {
            if currentCount < milestone {
                nextMilestone = milestone
                break
            }
        }
        
        // If we've exceeded all milestones, use the last one + increments of 100
        if currentCount >= milestones.last! {
            nextMilestone = ((currentCount / 100) + 1) * 100
        }
        
        let progress = Double(currentCount) / Double(nextMilestone)
        
        print("📊 StatsManager: Milestone progress - Current: \(currentCount), Target: \(nextMilestone), Progress: \(progress)")
        return (current: currentCount, target: nextMilestone, progress: progress)
    }
}

// MARK: - NSFetchRequest Extensions
extension UserStats {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserStats> {
        return NSFetchRequest<UserStats>(entityName: "UserStats")
    }
}

extension MenuAnalysis {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MenuAnalysis> {
        return NSFetchRequest<MenuAnalysis>(entityName: "MenuAnalysis")
    }
}
