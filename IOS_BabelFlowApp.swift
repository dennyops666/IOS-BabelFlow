//
//  IOS_BabelFlowApp.swift
//  IOS-BabelFlow
//
//  Created by Django on 12/25/24.
//

import SwiftUI

@main
struct IOS_BabelFlowApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // 调用测试函数
        testOpenAIKeyAccess()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // Removed .preferredColorScheme to use system default
        }
    }
}
