import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 调用测试函数
        testOpenAIKeyAccess()
        return true
    }

    // 其他代码...
}

import Foundation

func testOpenAIKeyAccess() {
    if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
        print("API Key successfully accessed: \(apiKey.prefix(5))...") // 只显示前5个字符
    } else {
        print("Failed to access API Key")
    }
}