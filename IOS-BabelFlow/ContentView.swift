//
//  ContentView.swift
//  IOS-BabelFlow
//
//  Created by Django on 12/25/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var inputText: String = "Please enter text to translate."
    @State private var translatedText: String = ""
    @State private var sourceLanguage: String = UserDefaults.standard.string(forKey: "defaultSourceLanguage") ?? "Auto"
    @State private var targetLanguage: String = UserDefaults.standard.string(forKey: "defaultTargetLanguage") ?? "English"
    @State private var isLoading: Bool = false
    @State private var isPaused: Bool = false
    @State private var showCopySuccessMessage: Bool = false
    @State private var showAPIKeySettings = false
    @State private var showAPIKeyAlert = false
    
    @StateObject private var themeManager = ThemeManager()
    
    let languages = ["Auto", "English", "Chinese", "Spanish", "French", "German", "Japanese", "Korean", "Russian", "Italian", "Portuguese"]
    
    private var translationService: TranslationService {
        TranslationService(apiKey: KeychainManager.shared.getAPIKey() ?? "")
    }
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        UIScrollView.appearance().indicatorStyle = .black
    }
    
    private func performTranslation() {
        guard !inputText.isEmpty else {
            translatedText = "Please enter text to translate."
            return
        }
        
        guard let _ = KeychainManager.shared.getAPIKey() else {
            showAPIKeyAlert = true
            return
        }
        
        isLoading = true
        let source = sourceLanguage == "Auto" ? "" : sourceLanguage
        translationService.translate(text: inputText, from: source, to: targetLanguage) { result in
            DispatchQueue.main.async {
                if let translatedResult = result {
                    translatedText = translatedResult
                } else {
                    translatedText = "Translation failed. Please check your internet connection or API Key."
                }
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
            HStack {
                Button(action: {
                    themeManager.toggleTheme()
                }) {
                    Image(systemName: themeManager.currentTheme == .light ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(.blue)
                }
                .padding()
                Spacer()
            }
            Text("BabelFlow Translator")
                .font(.largeTitle)
                .padding()
                .foregroundColor(themeManager.currentTheme == .light ? Color.black : Color.white)
            
            VStack {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(themeManager.currentTheme == .light ? Color.white : Color.black)
                            .border(Color.gray, width: 1)
                        
                        TextEditor(text: $inputText)
                            .frame(minHeight: 100, maxHeight: 200)
                            .foregroundColor(themeManager.currentTheme == .light ? Color.black : Color.white)
                            .scrollContentBackground(.hidden)
                            .onChange(of: inputText) { _ in
                                performTranslation()
                            }
                            .onSubmit {
                                performTranslation()
                            }
                            .onAppear {
                                UITextView.appearance().indicatorStyle = .black
                            }
                    }
                    .padding()
                    
                    Button(action: {
                        inputText = ""
                        translatedText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Clear Text")
                    .padding(.trailing, 25)
                    .padding(.top, 15)
                }
                .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme == .light ? Color.black : Color.white))
                        .padding(.vertical, 5)
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
                .padding(.trailing, 20)
            }
            
            HStack {
                Picker("Source Language", selection: $sourceLanguage) {
                    ForEach(languages, id: \ .self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Button(action: {
                    swapLanguages()
                }) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                Picker("Target Language", selection: $targetLanguage) {
                    ForEach(languages.dropFirst(), id: \ .self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding()

            Button(action: {
                performTranslation()
            }) {
                Text("Translate")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding()
            .alert(isPresented: $showAPIKeyAlert) {
                Alert(
                    title: Text("API Key Required"),
                    message: Text("Please set your OpenAI API Key in the settings to use the translation feature."),
                    primaryButton: .default(Text("Set API Key")) {
                        showAPIKeySettings = true
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showAPIKeySettings) {
                APIKeySettingsView()
            }
            
            Text("Translated Text:")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme == .light ? Color.black : Color.white)
                .padding(.top)
                
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    ZStack {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(themeManager.currentTheme == .light ? Color.white : Color.black)
                            .border(Color.gray, width: 1)
                        
                        Text(translatedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 100, maxHeight: 200)
                            .foregroundColor(themeManager.currentTheme == .light ? Color.black : Color.white)
                            .padding()
                    }
                }
                .onAppear {
                    UIScrollView.appearance().indicatorStyle = .black
                }
                
                Button(action: {
                    UIPasteboard.general.string = translatedText
                    showCopySuccessMessage = true
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Copy Translation")
                .padding(.trailing, 25)
                .padding(.top, 15)
            }
            .padding(.horizontal)
            .alert(isPresented: $showCopySuccessMessage) {
                Alert(title: Text("复制成功"), message: Text("翻译内容已复制到剪贴板。"), dismissButton: .default(Text("确定")))
            }
            
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
            .padding(.trailing, 20)

            Spacer()
        }
        .background(themeManager.currentTheme == .light ? Color.white : Color.black)
        .animation(.easeInOut, value: themeManager.currentTheme)
        .padding()
        .alert(isPresented: $showAPIKeyAlert) {
            Alert(title: Text("API Key Required"), message: Text("Please enter your OpenAI API Key in the settings."), dismissButton: .default(Text("OK")) {
                showAPIKeySettings = true
            })
        }
        .sheet(isPresented: $showAPIKeySettings) {
            NavigationView {
                APIKeySettingsView()
            }
        }
    }
    
    private func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
    }
}

struct APIKeySettingsView: View {
    @State private var apiKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OpenAI API Key")) {
                    SecureField("Enter API Key", text: $apiKey)
                    Button("Save API Key") {
                        if KeychainManager.shared.saveAPIKey(apiKey) {
                            alertMessage = "API Key saved successfully"
                            showAlert = true
                        } else {
                            alertMessage = "Failed to save API Key"
                            showAlert = true
                        }
                    }
                }
                
                Section {
                    Button("Delete API Key") {
                        if KeychainManager.shared.deleteAPIKey() {
                            apiKey = ""
                            alertMessage = "API Key deleted successfully"
                            showAlert = true
                        } else {
                            alertMessage = "Failed to delete API Key"
                            showAlert = true
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("API Key Settings")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notice"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("successfully") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("defaultSourceLanguage") private var defaultSourceLanguage = "Auto"
    @AppStorage("defaultTargetLanguage") private var defaultTargetLanguage = "English"
    @State private var showAPIKeySettings = false
    @State private var useCustomAPIKey = KeychainManager.shared.isUsingCustomKey()
    
    var body: some View {
        Form {
            Section(header: Text("Default Languages")) {
                Picker("Source Language", selection: $defaultSourceLanguage) {
                    Text("Auto").tag("Auto")
                    ForEach(["English", "Chinese", "Spanish", "French", "German", "Japanese", "Korean", "Russian", "Italian", "Portuguese"], id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                
                Picker("Target Language", selection: $defaultTargetLanguage) {
                    ForEach(["English", "Chinese", "Spanish", "French", "German", "Japanese", "Korean", "Russian", "Italian", "Portuguese"], id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
            }
            
            Section(header: Text("API Settings")) {
                Toggle("Use Custom API Key", isOn: Binding(
                    get: { useCustomAPIKey },
                    set: { newValue in
                        useCustomAPIKey = newValue
                        KeychainManager.shared.setUseCustomKey(newValue)
                    }
                ))
                .onChange(of: useCustomAPIKey) { _ in
                    // 当切换到使用环境变量时，可以选择是否清除已保存的自定义 API Key
                    if !useCustomAPIKey {
                        _ = KeychainManager.shared.deleteAPIKey()
                    }
                }
                
                if useCustomAPIKey {
                    Button("Set Custom API Key") {
                        showAPIKeySettings = true
                    }
                } else {
                    Text("Using Environment Variable API Key")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showAPIKeySettings) {
            APIKeySettingsView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Translate", systemImage: "text.bubble")
                }

            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            
            NavigationView {
                APIKeySettingsView()
            }
            .tabItem {
                Label("API Key", systemImage: "key.fill")
            }
        }
    }
}
