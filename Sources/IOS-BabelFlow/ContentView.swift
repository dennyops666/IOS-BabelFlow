import SwiftUI
import Combine
import Foundation
import NaturalLanguage

@available(macOS 12.0, *)
public struct ContentView: View {
    @StateObject private var translationService = TranslationService()
    @StateObject private var speechRecognizer = SpeechRecognitionManager()
    @State private var sourceText: String = ""
    @State private var translatedText: String = ""
    @State private var sourceLanguage: String = UserDefaults.standard.string(forKey: "defaultSourceLanguage") ?? "Auto"
    @State private var targetLanguage: String = UserDefaults.standard.string(forKey: "defaultTargetLanguage") ?? "English"
    @State private var isRecording = false
    @State private var showSettings = false
    @State private var showAPIKeySettings = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private func getLocaleIdentifier(for language: String) -> String {
        if language == "Auto" {
            // Default to Chinese for Auto mode when text contains Chinese characters
            if sourceText.range(of: "\\p{Han}", options: .regularExpression) != nil {
                return "zh-CN"
            }
            return "auto"
        }
        
        switch language {
        case "Chinese":
            return "zh-CN"
        case "English":
            return "en-US"
        case "Japanese":
            return "ja-JP"
        case "Korean":
            return "ko-KR"
        case "Spanish":
            return "es-ES"
        case "French":
            return "fr-FR"
        case "German":
            return "de-DE"
        default:
            return "en-US"
        }
    }
    
    private func getLanguageFromLocale(_ identifier: String) -> String {
        switch identifier {
        case "zh-CN":
            return "Chinese"
        case "en-US":
            return "English"
        case "ja-JP":
            return "Japanese"
        case "ko-KR":
            return "Korean"
        case "es-ES":
            return "Spanish"
        case "fr-FR":
            return "French"
        case "de-DE":
            return "German"
        default:
            return "English"
        }
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $sourceText)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding()
                
                HStack {
                    Button(action: {
                        if !speechRecognizer.isRecording {
                            // 设置语音识别器的语言
                            let locale = getLocaleIdentifier(for: sourceLanguage)
                            withAnimation {
                                speechRecognizer.currentLocaleIdentifier = locale
                            }
                            
                            speechRecognizer.startRecording { text in
                                sourceText = text
                                
                                // 如果是自动模式，根据检测到的语言更新源语言
                                if sourceLanguage == "Auto" {
                                    // First check for Chinese characters
                                    if text.range(of: "\\p{Han}", options: .regularExpression) != nil {
                                        withAnimation {
                                            sourceLanguage = "Chinese"
                                        }
                                    } else {
                                        // Use NLLanguageRecognizer as fallback
                                        let languageRecognizer = NLLanguageRecognizer()
                                        languageRecognizer.processString(text)
                                        
                                        if let detectedLanguage = languageRecognizer.dominantLanguage?.rawValue {
                                            let language = getLanguageFromLocale(detectedLanguage)
                                            withAnimation {
                                                sourceLanguage = language
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            speechRecognizer.stopRecording()
                        }
                    }) {
                        Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Translate") {
                        Task {
                            do {
                                translatedText = try await translationService.translate(
                                    text: sourceText,
                                    from: sourceLanguage,
                                    to: targetLanguage
                                )
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sourceText.isEmpty)
                }
                .padding()
                
                TextEditor(text: .constant(translatedText))
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding()
                
                Spacer()
                
                HStack {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showAPIKeySettings = true }) {
                        Image(systemName: "key")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("BabelFlow")
            .sheet(isPresented: $showSettings) {
                if #available(macOS 12.0, *) {
                    SettingsView()
                }
            }
            .sheet(isPresented: $showAPIKeySettings) {
                if #available(macOS 12.0, *) {
                    APIKeySettingsView(translationService: translationService)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .onChange(of: sourceLanguage) { newLanguage in
                let locale = getLocaleIdentifier(for: newLanguage)
                withAnimation {
                    speechRecognizer.currentLocaleIdentifier = locale
                }
            }
        }
    }
}

#if DEBUG
@available(macOS 12.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
