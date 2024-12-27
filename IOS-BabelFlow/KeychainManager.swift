import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private let apiKeyKey = "com.babelflow.apikey"
    private let useCustomKeyKey = "com.babelflow.useCustomKey"
    
    // 默认的 API Key
    private let defaultAPIKey = "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"
    
    private init() {}
    
    func saveAPIKey(_ apiKey: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apiKeyKey,
            kSecValueData as String: apiKey.data(using: .utf8)!
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            setUseCustomKey(true)
        }
        return status == errSecSuccess
    }
    
    func getAPIKey() -> String? {
        // 如果使用自定义 Key，从 Keychain 获取
        if isUsingCustomKey() {
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
        }
        
        // 如果没有使用自定义 Key 或获取失败，返回默认的 API Key
        return defaultAPIKey
    }
    
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apiKeyKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            setUseCustomKey(false)
        }
        return status == errSecSuccess
    }
    
    func setUseCustomKey(_ useCustom: Bool) {
        UserDefaults.standard.set(useCustom, forKey: useCustomKeyKey)
    }
    
    func isUsingCustomKey() -> Bool {
        return UserDefaults.standard.bool(forKey: useCustomKeyKey)
    }
}
