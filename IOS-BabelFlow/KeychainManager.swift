import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private let apiKeyKey = "com.babelflow.apikey"
    private let useCustomKeyKey = "com.babelflow.useCustomKey"
    
    private init() {}
    
    func saveAPIKey(_ apiKey: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apiKeyKey,
            kSecValueData as String: apiKey.data(using: .utf8)!
        ]
        
        // 先删除已存在的数据
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getAPIKey() -> String? {
        // 如果使用环境变量，返回环境变量中的 API Key
        if !UserDefaults.standard.bool(forKey: useCustomKeyKey) {
            return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        }
        
        // 否则返回存储在 Keychain 中的 API Key
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apiKeyKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let apiKey = String(data: data, encoding: .utf8) {
            return apiKey
        }
        return nil
    }
    
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apiKeyKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    func setUseCustomKey(_ useCustom: Bool) {
        UserDefaults.standard.set(useCustom, forKey: useCustomKeyKey)
    }
    
    func isUsingCustomKey() -> Bool {
        return UserDefaults.standard.bool(forKey: useCustomKeyKey)
    }
}
