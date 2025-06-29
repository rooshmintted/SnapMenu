//
//  MenuCrimesDataModel.swift
//  Menu Crimes
//
//  Core Data model setup for menu analysis tracking
//

import CoreData
import Foundation

/// Core Data model configuration for Menu Crimes
extension PersistenceController {
    
    /// Create the Core Data model programmatically
    /// This defines the UserStats entity for tracking menu analysis statistics
    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // MARK: - UserStats Entity
        let userStatsEntity = NSEntityDescription()
        userStatsEntity.name = "UserStats"
        userStatsEntity.managedObjectClassName = "UserStats"
        
        // menusSubmitted attribute
        let menusSubmittedAttribute = NSAttributeDescription()
        menusSubmittedAttribute.name = "menusSubmitted"
        menusSubmittedAttribute.attributeType = .integer32AttributeType
        menusSubmittedAttribute.defaultValue = 0
        menusSubmittedAttribute.isOptional = false
        
        // dishesAnalyzed attribute
        let dishesAnalyzedAttribute = NSAttributeDescription()
        dishesAnalyzedAttribute.name = "dishesAnalyzed"
        dishesAnalyzedAttribute.attributeType = .integer32AttributeType
        dishesAnalyzedAttribute.defaultValue = 0
        dishesAnalyzedAttribute.isOptional = false
        
        // lastUpdated attribute
        let lastUpdatedAttribute = NSAttributeDescription()
        lastUpdatedAttribute.name = "lastUpdated"
        lastUpdatedAttribute.attributeType = .dateAttributeType
        lastUpdatedAttribute.defaultValue = Date()
        lastUpdatedAttribute.isOptional = false
        
        // userID attribute (to track different users)
        let userIDAttribute = NSAttributeDescription()
        userIDAttribute.name = "userID"
        userIDAttribute.attributeType = .stringAttributeType
        userIDAttribute.isOptional = true
        
        // Add attributes to entity
        userStatsEntity.properties = [
            menusSubmittedAttribute,
            dishesAnalyzedAttribute,
            lastUpdatedAttribute,
            userIDAttribute
        ]
        
        // MARK: - MenuAnalysis Entity (for tracking individual analyses)
        let menuAnalysisEntity = NSEntityDescription()
        menuAnalysisEntity.name = "MenuAnalysis"
        menuAnalysisEntity.managedObjectClassName = "MenuAnalysis"
        
        // analysisDate attribute
        let analysisDateAttribute = NSAttributeDescription()
        analysisDateAttribute.name = "analysisDate"
        analysisDateAttribute.attributeType = .dateAttributeType
        analysisDateAttribute.defaultValue = Date()
        analysisDateAttribute.isOptional = false
        
        // dishCount attribute
        let dishCountAttribute = NSAttributeDescription()
        dishCountAttribute.name = "dishCount"
        dishCountAttribute.attributeType = .integer32AttributeType
        dishCountAttribute.defaultValue = 0
        dishCountAttribute.isOptional = false
        
        // userID attribute
        let analysisUserIDAttribute = NSAttributeDescription()
        analysisUserIDAttribute.name = "userID"
        analysisUserIDAttribute.attributeType = .stringAttributeType
        analysisUserIDAttribute.isOptional = true
        
        // Add attributes to entity
        menuAnalysisEntity.properties = [
            analysisDateAttribute,
            dishCountAttribute,
            analysisUserIDAttribute
        ]
        
        // Add entities to model
        model.entities = [userStatsEntity, menuAnalysisEntity]
        
        print("📊 MenuCrimesDataModel: Core Data model created with UserStats and MenuAnalysis entities")
        return model
    }
}

// MARK: - NSManagedObject Extensions

/// Core Data entity for tracking user statistics
@objc(UserStats)
public class UserStats: NSManagedObject {
    @NSManaged public var menusSubmitted: Int32
    @NSManaged public var dishesAnalyzed: Int32
    @NSManaged public var lastUpdated: Date
    @NSManaged public var userID: String?
    
    /// Convenience initializer
    convenience init(context: NSManagedObjectContext, userID: String? = nil) {
        self.init(context: context)
        self.menusSubmitted = 0
        self.dishesAnalyzed = 0
        self.lastUpdated = Date()
        self.userID = userID
        print("📊 UserStats: Created new UserStats entity for user: \(userID ?? "unknown")")
    }
}

/// Core Data entity for tracking individual menu analyses
@objc(MenuAnalysis)
public class MenuAnalysis: NSManagedObject {
    @NSManaged public var analysisDate: Date
    @NSManaged public var dishCount: Int32
    @NSManaged public var userID: String?
    
    /// Convenience initializer
    convenience init(context: NSManagedObjectContext, dishCount: Int32, userID: String? = nil) {
        self.init(context: context)
        self.analysisDate = Date()
        self.dishCount = dishCount
        self.userID = userID
        print("📊 MenuAnalysis: Created new analysis record with \(dishCount) dishes for user: \(userID ?? "unknown")")
    }
}
