import Foundation
import SwiftUI

@available(macOS 10.15, *)
public class TranslationService: ObservableObject {
    @Published public var apiKey: String = ""
    @Published public var useCustomAPIKey: Bool = false
    
    private let keychainManager = KeychainManager.shared
    
    public init() {
        loadAPIKey()
    }
    
    public func saveAPIKey(_ key: String) throws {
        try keychainManager.saveAPIKey(key)
        apiKey = key
        useCustomAPIKey = !key.isEmpty
    }
    
    public func loadAPIKey() {
        do {
            if let key = try keychainManager.loadAPIKey() {
                apiKey = key
                useCustomAPIKey = !key.isEmpty
            }
        } catch {
            print("Error loading API key: \(error)")
        }
    }
    
    public func translate(text: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        // 在这里实现翻译逻辑
        // 可以使用您选择的翻译 API，如 Google Translate、DeepL 等
        // 目前返回一个占位符结果
        return "Translated: \(text)"
    }
}
