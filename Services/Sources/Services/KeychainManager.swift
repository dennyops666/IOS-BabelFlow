import Foundation
import KeychainAccess

class KeychainManager {
    static let shared: KeychainManager = KeychainManager()
    private let keychain = Keychain(service: "com.babelflow.apikey")
    private let apiKeyKey = "openai_api_key"
    
    init() {} // 公共初始化器
    
    func saveAPIKey(_ key: String) throws {
        try keychain.set(key, key: apiKeyKey)
    }
    
    func loadAPIKey() throws -> String? {
        return try keychain.get(apiKeyKey)
    }
    
    func deleteAPIKey() throws {
        try keychain.remove(apiKeyKey)
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToDelete
}
