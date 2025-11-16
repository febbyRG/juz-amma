//
//  JuzAmmaApp.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import SwiftUI
import SwiftData

@main
struct JuzAmmaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Surah.self,
            Ayah.self,
            AppSettings.self,
            Translation.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, try to recreate container
            print("Migration error: \(error)")
            
            // Delete old store and create fresh one
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
