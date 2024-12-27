//
//  IOS_BabelFlowApp.swift
//  IOS-BabelFlow
//
//  Created by Django on 12/25/24.
//

import SwiftUI

@main
struct IOS_BabelFlowApp: App {
    @StateObject private var themeManager = ThemeManager()
    @State private var useCustomAPIKey = KeychainManager.shared.isUsingCustomKey()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationView {
                    ContentView(useCustomAPIKey: $useCustomAPIKey)
                }
                .tabItem {
                    Label("Translate", systemImage: "text.bubble")
                }
                
                NavigationView {
                    SettingsView(useCustomAPIKey: $useCustomAPIKey)
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
