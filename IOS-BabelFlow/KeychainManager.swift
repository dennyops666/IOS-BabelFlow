import Foundation
import Security
import CryptoKit

class KeychainManager {
    static let shared = KeychainManager()
    private let apiKeyKey = "com.babelflow.apikey"
    private let useCustomKeyKey = "com.babelflow.useCustomKey"
    
    // 加密后的 API Key（使用简单的位移加密）
    private let encryptedAPIKey = "tl-qspk-Ql-NLUci--WbPl9Tj5V_[U{s5mYVkE8H9qlN9b7iizPrEVYC8_To8LNj95XYrLFv-kQkD9GZyiU4CmclGKQsMDqO7jxRVdP{HK2onHlnqJe3oxJQwYjTDfOds:FTqp-o6fS5QoEy-SZuXvLDiH[p{fP-Cl5B"
    
    private var defaultAPIKey: String {
        // 解密 API Key
        return decryptAPIKey(encryptedAPIKey)
    }
    
    private init() {
        if !hasCustomAPIKey() {
            setUseCustomKey(false)
        }
    }
    
    // 简单的解密方法
    private func decryptAPIKey(_ encrypted: String) -> String {
        var decrypted = ""
        let shift = 1 // 位移量
        
        for char in encrypted {
            if char == "." || char == "-" || char == "_" {
                decrypted.append(char)
                continue
            }
            
            if let ascii = char.asciiValue {
                if let decryptedChar = UnicodeScalar(Int(ascii) - shift) {
                    decrypted.append(String(decryptedChar))
                }
            } else {
                decrypted.append(char)
            }
        }
        
        return decrypted
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
