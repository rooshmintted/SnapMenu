//
//  Menu_CrimesApp.swift
//  Menu Crimes
//
//  Created by Roosh on 6/23/25.
//

import SwiftUI

@main
struct Menu_CrimesApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
