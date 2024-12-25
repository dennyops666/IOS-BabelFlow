import Foundation

class TranslationService {
    let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func translate(text: String, from sourceLanguage: String, to targetLanguage: String, completion: @escaping (String?) -> Void) {
        // 构建请求
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "Translate the following text from \(sourceLanguage) to \(targetLanguage):"],
                ["role": "user", "content": text]
            ],
            "max_tokens": 100
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            completion(nil)
            return
        }
        
        // 打印请求
        print("Request URL: \(url)")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
        
        // 发起请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            // 打印响应
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            
            // 解析响应
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                print("Failed to parse response")
                completion(nil)
            }
        }.resume()
    }
}
