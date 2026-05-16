//
//  WatchTowerApp.swift
//  WatchTower
//
//  Created by Артем Потапов on 17.05.2026.
//

import SwiftUI
import CoreData

@main
struct WatchTowerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
