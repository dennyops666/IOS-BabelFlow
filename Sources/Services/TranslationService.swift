import Foundation
import SwiftUI

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
        // 实现翻译逻辑
        return "Translated: \(text)"
    }
}
