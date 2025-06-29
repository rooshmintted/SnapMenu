//
//  PersistenceController.swift
//  Menu Crimes
//
//  Core Data persistence manager for tracking user analytics
//  Tracks menu submissions, dishes analyzed, and achievements
//

import CoreData
import Foundation

/// Core Data persistence controller for managing user statistics
final class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    /// In-memory store for previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let stats = UserStats(context: viewContext)
        stats.menusSubmitted = 5
        stats.dishesAnalyzed = 27
        stats.lastUpdated = Date()
        
        do {
            try viewContext.save()
            print("📊 PersistenceController: Preview data created successfully")
        } catch {
            print("❌ PersistenceController: Failed to create preview data: \(error)")
        }
        
        return result
    }()
    
    init(inMemory: Bool = false) {
        // Create container with programmatic model
        container = NSPersistentContainer(name: "MenuCrimesDataModel", managedObjectModel: Self.createModel())
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("❌ PersistenceController: Core Data error: \(error), \(error.userInfo)")
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            } else {
                print("📊 PersistenceController: Core Data store loaded successfully")
            }
        }
        
        // Enable automatic merging of changes from background contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// Save the Core Data context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("📊 PersistenceController: Context saved successfully")
            } catch {
                print("❌ PersistenceController: Save error: \(error)")
            }
        }
    }
}
