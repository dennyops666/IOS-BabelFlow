import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private let apiKeyKey = "com.babelflow.apikey"
    private let useCustomKeyKey = "com.babelflow.useCustomKey"
    
    // 默认的 API Key
    private let defaultAPIKey = "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"
    
    private init() {
        // 初始化时，如果没有自定义 Key，确保使用默认 Key
        if !hasCustomAPIKey() {
            setUseCustomKey(false)
        }
    }
    
    private func keychainQuery() -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apiKeyKey,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
    }
    
    func saveAPIKey(_ apiKey: String) -> Bool {
        var query = keychainQuery()
        let encodedData = apiKey.data(using: .utf8)!
        query[kSecValueData as String] = encodedData
        
        // 先尝试删除已存在的数据
        SecItemDelete(query as CFDictionary)
        
        // 添加新数据
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            // 保存成功后自动开启自定义 Key
            setUseCustomKey(true)
            NotificationCenter.default.post(name: NSNotification.Name("APIKeyStatusChanged"), object: nil)
            return true
        }
        print("Failed to save API Key: \(status)")
        return false
    }
    
    func getAPIKey() -> String? {
        if isUsingCustomKey() && hasCustomAPIKey() {
            // 如果使用自定义 Key 且存在自定义 Key，从 Keychain 获取
            var query = keychainQuery()
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            if status == errSecSuccess,
               let data = result as? Data,
               let apiKey = String(data: data, encoding: .utf8) {
                return apiKey
            }
            
            print("Failed to get API Key: \(status)")
            // 如果获取失败，切换到默认 Key
            setUseCustomKey(false)
            NotificationCenter.default.post(name: NSNotification.Name("APIKeyStatusChanged"), object: nil)
        }
        
        // 如果没有使用自定义 Key 或获取失败，返回默认的 API Key
        return defaultAPIKey
    }
    
    func deleteAPIKey() -> Bool {
        let query = keychainQuery()
        let status = SecItemDelete(query as CFDictionary)
        
        // 删除 Key 时设置为不使用自定义 Key
        setUseCustomKey(false)
        NotificationCenter.default.post(name: NSNotification.Name("APIKeyStatusChanged"), object: nil)
        
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func setUseCustomKey(_ useCustom: Bool) {
        // 如果要使用自定义 Key 但没有自定义 Key，则不允许
        if useCustom && !hasCustomAPIKey() {
            return
        }
        UserDefaults.standard.set(useCustom, forKey: useCustomKeyKey)
        NotificationCenter.default.post(name: NSNotification.Name("APIKeyStatusChanged"), object: nil)
    }
    
    func isUsingCustomKey() -> Bool {
        // 如果没有自定义 Key，强制使用默认 Key
        if !hasCustomAPIKey() {
            setUseCustomKey(false)
            return false
        }
        return UserDefaults.standard.bool(forKey: useCustomKeyKey)
    }
    
    func hasCustomAPIKey() -> Bool {
        var query = keychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == errSecSuccess
    }
}
