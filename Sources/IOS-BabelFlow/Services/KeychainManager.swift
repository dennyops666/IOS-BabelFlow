import Foundation
import KeychainAccess

public class KeychainManager {
    public static let shared = KeychainManager()
    private let keychain = Keychain(service: "com.babelflow.apikey")
    private let apiKeyKey = "openai_api_key"
    
    public init() {}
    
    public func saveAPIKey(_ key: String) throws {
        try keychain.set(key, key: apiKeyKey)
    }
    
    public func loadAPIKey() throws -> String? {
        try keychain.get(apiKeyKey)
    }
    
    public func deleteAPIKey() throws {
        try keychain.remove(apiKeyKey)
    }
}
