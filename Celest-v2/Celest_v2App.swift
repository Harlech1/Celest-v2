//
//  Celest_v2App.swift
//  Celest-v2
//
//  Created by Türker Kızılcık on 12.06.2025.
//

import SwiftUI

@main
struct Celest_v2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.lodge")
                        }
                    
                    WaterLogView()
                        .tabItem {
                            Label("Water", systemImage: "drop.fill")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                FirstOnboardingView()
            }
        }
    }
}
