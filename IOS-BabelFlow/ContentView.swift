//
//  ContentView.swift
//  IOS-BabelFlow
//
//  Created by Django on 12/25/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var sourceLanguage: String = UserDefaults.standard.string(forKey: "defaultSourceLanguage") ?? "Auto"
    @State private var targetLanguage: String = UserDefaults.standard.string(forKey: "defaultTargetLanguage") ?? "English"
    @State private var isLoading: Bool = false
    @State private var isPaused: Bool = false
    
    let languages = ["Auto", "English", "Chinese", "Spanish", "French", "German", "Japanese", "Korean", "Russian", "Italian", "Portuguese"]
    
    let translationService = TranslationService(apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "")
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    private func performTranslation() {
        guard !inputText.isEmpty else {
            translatedText = "Please enter text to translate."
            return
        }
        
        isLoading = true
        let source = sourceLanguage == "Auto" ? "" : sourceLanguage
        translationService.translate(text: inputText, from: source, to: targetLanguage) { result in
            DispatchQueue.main.async {
                translatedText = result ?? "Translation failed. Please check your internet connection or try again later."
                isLoading = false
            }
        }
    }
    
    func speakTranslatedText(_ text: String, language: String) {
        // Map language names to language codes
        let languageCode: String
        switch language.lowercased() {
        case "korean":
            languageCode = "ko-KR"
        case "russian":
            languageCode = "ru-RU"
        default:
            languageCode = language // Use the provided language if not Korean or Russian
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        speechSynthesizer.speak(utterance)
    }
    
    var body: some View {
        VStack {
            Text("BabelFlow Translator")
                .font(.largeTitle)
                .padding()
            
            TextEditor(text: $inputText)
                .frame(height: 100)
                .border(Color.gray, width: 1)
                .padding()
                .onTapGesture {
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .onChange(of: inputText) { _ in
                    performTranslation()
                }
            
            HStack(spacing: 4) {
                Spacer()
                Button(action: {
                    speakTranslatedText(inputText, language: sourceLanguage)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Speak Input")
                Button(action: {
                    if isPaused {
                        speechSynthesizer.continueSpeaking()
                    } else {
                        speechSynthesizer.pauseSpeaking(at: .immediate)
                    }
                    isPaused.toggle()
                }) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help(isPaused ? "Continue Speech" : "Pause Speech")
                Button(action: {
                    speechSynthesizer.stopSpeaking(at: .immediate)
                }) {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Stop Speech")
            }
            .padding(.trailing, 20) // Move buttons slightly left from the right edge
            
            HStack {
                Picker("Source Language", selection: $sourceLanguage) {
                    ForEach(languages, id: \ .self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Picker("Target Language", selection: $targetLanguage) {
                    ForEach(languages.dropFirst(), id: \ .self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding()

            Button("Translate") {
                performTranslation()
            }
            .padding()
            
            if isLoading {
                ProgressView()
                    .padding()
            }

            Text("Translated Text:")
                .font(.headline)
                .padding(.top)
            
            TextEditor(text: $translatedText)
                .frame(height: 100)
                .border(Color.gray, width: 1)
                .padding()
                .disabled(true)

            HStack(spacing: 4) {
                Spacer()
                Button(action: {
                    speakTranslatedText(translatedText, language: targetLanguage)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Speak Translation")
                Button(action: {
                    if isPaused {
                        speechSynthesizer.continueSpeaking()
                    } else {
                        speechSynthesizer.pauseSpeaking(at: .immediate)
                    }
                    isPaused.toggle()
                }) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help(isPaused ? "Continue Speech" : "Pause Speech")
                Button(action: {
                    speechSynthesizer.stopSpeaking(at: .immediate)
                }) {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Stop Speech")
            }
            .padding(.trailing, 20) // Move buttons two spaces further right

            Button("Copy Translation") {
                UIPasteboard.general.string = translatedText
            }
            .padding()

            Spacer()
        }
        .padding()
    }
}

struct SettingsView: View {
    @AppStorage("defaultSourceLanguage") private var defaultSourceLanguage = "Auto"
    @AppStorage("defaultTargetLanguage") private var defaultTargetLanguage = "English"
    @AppStorage("fontSize") private var fontSize: Double = 14

    let languages = ["Auto", "English", "Chinese", "Spanish", "French", "German", "Japanese", "Korean", "Russian", "Italian", "Portuguese"]

    var body: some View {
        Form {
            Picker("Default Source Language", selection: $defaultSourceLanguage) {
                ForEach(languages, id: \ .self) {
                    Text($0)
                }
            }

            Picker("Default Target Language", selection: $defaultTargetLanguage) {
                ForEach(languages.dropFirst(), id: \ .self) {
                    Text($0)
                }
            }

            Slider(value: $fontSize, in: 10...24, step: 1) {
                Text("Font Size")
            }
        }
        .navigationTitle("Settings")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Translate", systemImage: "text.bubble")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
