//
//  IOS_BabelFlowApp.swift
//  IOS-BabelFlow
//
//  Created by Django on 12/25/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Translate", systemImage: "text.bubble")
                }
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

@main
struct IOS_BabelFlowApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
