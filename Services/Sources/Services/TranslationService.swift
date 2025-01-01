import Foundation
import KeychainAccess

public final class TranslationService: ObservableObject {
    @Published public var useCustomAPIKey: Bool = false
    @Published public var apiKey: String = ""
    
    private let keychainManager = KeychainManager()
    
    public init() {
        if let savedKey = try? keychainManager.loadAPIKey() {
            apiKey = savedKey
            useCustomAPIKey = true
        }
    }
    
    public func translate(text: String, from: String, to: String) async throws -> String {
        guard !text.isEmpty else {
            return ""
        }
        
        let key = useCustomAPIKey ? try keychainManager.loadAPIKey() : apiKey
        guard let apiKey = key else {
            throw TranslationError.missingAPIKey
        }
        
        let endpoint = "https://api.openai.com/v1/chat/completions"
        let sourceLocale = mapLanguageToLocale(from)
        let targetLocale = mapLanguageToLocale(to)
        
        let prompt = """
        Translate the following text from \(sourceLocale) to \(targetLocale):
        \(text)
        
        Only return the translated text, without any additional context or explanation.
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a professional translator."],
                ["role": "user", "content": prompt]
            ]
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TranslationError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }
    
    public func saveAPIKey(_ key: String) throws {
        try keychainManager.saveAPIKey(key)
        apiKey = key
        useCustomAPIKey = !key.isEmpty
    }
    
    public func loadAPIKey() throws -> String? {
        try keychainManager.loadAPIKey()
    }
    
    private func mapLanguageToLocale(_ language: String) -> String {
        switch language.lowercased() {
        case "english": return "en"
        case "chinese": return "zh"
        case "japanese": return "ja"
        case "korean": return "ko"
        case "spanish": return "es"
        case "french": return "fr"
        case "german": return "de"
        default: return language
        }
    }
}

private struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

public enum TranslationError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode):
            return "API error with status code: \(statusCode)"
        }
    }
}
