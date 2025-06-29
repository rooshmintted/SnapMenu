//
//  Menu_CrimesApp.swift
//  Menu Crimes
//
//  Created by Roosh on 6/23/25.
//

import SwiftUI

@main
struct Menu_CrimesApp: App {
    // Core Data persistence controller
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    print("🍽️ Menu_CrimesApp: App launched with Core Data")
                }
        }
    }
}
