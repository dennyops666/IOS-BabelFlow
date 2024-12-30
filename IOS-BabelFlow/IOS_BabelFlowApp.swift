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
    let persistenceController = PersistenceController.shared
    
    init() {
        // 测试 OpenAI API Key
        Task { [self] in
            await testOpenAIKey()
        }
    }
    
    private func testOpenAIKey() async {
        if let apiKey = KeychainManager.shared.getAPIKey() {
            print("Testing OpenAI API Key...")
            let translationService = TranslationService(apiKey: apiKey)
            do {
                let result = try await translationService.translateText("Hello", from: "en", to: "zh")
                print("API Key test successful! Translation result: \(result)")
            } catch {
                print("API Key test failed: \(error)")
            }
        } else {
            print("No API Key available")
        }
    }

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
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
