import SwiftUI
import AVFoundation
import NaturalLanguage
import Speech
import Combine

class SpeechRecognitionManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        guard let speechRecognizer = speechRecognizer else {
            errorMessage = "Speech recognition is not available"
            return
        }
        
        if !speechRecognizer.isAvailable {
            errorMessage = "Speech recognition is not currently available"
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // 重置之前的任务
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // 请求麦克风权限
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            guard let self = self else { return }
            
            if !allowed {
                self.errorMessage = "Microphone access denied"
                return
            }
            
            self.startRecordingWithPermission()
        }
    }
    
    private func startRecordingWithPermission() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "Unable to create recognition request"
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.stopRecording()
                    return
                }
                
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isRecording = false
    }
}

struct ContentView: View {
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var sourceLanguage = UserDefaults.standard.string(forKey: "defaultSourceLanguage") ?? "Auto"
    @State private var targetLanguage = UserDefaults.standard.string(forKey: "defaultTargetLanguage") ?? "English"
    @State private var isLoading = false
    @State private var isPaused = false
    @State private var showCopySuccessMessage = false
    @State private var showAPIKeySettings = false
    @State private var showAPIKeyAlert = false
    @State private var lastTranslationTask: Task<Void, Never>?
    @Binding var useCustomAPIKey: Bool
    @StateObject private var speechRecognizer = SpeechRecognitionManager()
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    
    let languages = ["Auto", "English", "Chinese", "Spanish", "French", "German", "Japanese", "Korean", "Russian", "Italian", "Portuguese"]
    
    init(useCustomAPIKey: Binding<Bool>) {
        _useCustomAPIKey = useCustomAPIKey
        _speechRecognizer = StateObject(wrappedValue: SpeechRecognitionManager())
    }
    
    private var translationService: TranslationService {
        TranslationService(apiKey: KeychainManager.shared.getAPIKey() ?? "")
    }
    
    func translate() {
        guard !inputText.isEmpty else { return }
        
        // Cancel any ongoing translation
        lastTranslationTask?.cancel()
        
        isLoading = true
        lastTranslationTask = Task {
            do {
                let result = try await translationService.translateText(
                    inputText,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                
                if !Task.isCancelled {
                    translatedText = result
                }
            } catch {
                if !Task.isCancelled {
                    translatedText = "Translation failed: \(error.localizedDescription)"
                }
            }
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Language Selection
            HStack(spacing: 4) {
                Menu {
                    Picker("Source Language", selection: $sourceLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                } label: {
                    Text(sourceLanguage)
                        .foregroundColor(.blue)
                        .frame(minWidth: 80, alignment: .leading)
                }
                
                Button(action: {
                    let temp = sourceLanguage
                    sourceLanguage = targetLanguage
                    targetLanguage = temp
                    if !translatedText.isEmpty {
                        let tempText = inputText
                        inputText = translatedText
                        translatedText = tempText
                    }
                }) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.blue)
                }
                .frame(width: 40)
                
                Menu {
                    Picker("Target Language", selection: $targetLanguage) {
                        ForEach(languages.dropFirst(), id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                } label: {
                    Text(targetLanguage)
                        .foregroundColor(.blue)
                        .frame(minWidth: 80, alignment: .leading)
                }
            }
            
            // Input Area
            VStack(alignment: .leading) {
                HStack {
                    Text("Please enter text to translate.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: {
                            if speechRecognizer.isRecording {
                                speechRecognizer.stopRecording()
                            } else {
                                speechRecognizer.startRecording()
                            }
                        }) {
                            Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                                .foregroundColor(speechRecognizer.isRecording ? .red : .blue)
                        }
                        .buttonStyle(.borderless)
                        .disabled(isLoading)
                        
                        Button(action: {
                            if !inputText.isEmpty {
                                speakText(inputText, language: sourceLanguage)
                            }
                        }) {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.blue)
                        }
                        .disabled(inputText.isEmpty)
                        
                        Button(action: {
                            if isPaused {
                                speechSynthesizer.continueSpeaking()
                            } else {
                                speechSynthesizer.pauseSpeaking(at: .immediate)
                            }
                            isPaused.toggle()
                        }) {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(inputText.isEmpty)
                        
                        Button(action: {
                            speechSynthesizer.stopSpeaking(at: .immediate)
                            isPaused = false
                        }) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(inputText.isEmpty)
                        
                        Button(action: {
                            inputText = ""
                            translatedText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.borderless)
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                TextEditor(text: $inputText)
                    .frame(height: 180)
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .onChange(of: inputText) { newValue in
                        // Auto translate after 0.5 seconds of no typing
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            translate()
                        }
                    }
                    .onSubmit {
                        // Translate when return key is pressed
                        translate()
                    }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            
            // Translate Button
            Button(action: translate) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text("Translate")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(inputText.isEmpty || isLoading)
            
            // Translation Result
            VStack(spacing: 0) {
                HStack {
                    Text("Translation")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    if !translatedText.isEmpty {
                        HStack(spacing: 8) {
                            Button(action: {
                                speakText(translatedText, language: targetLanguage)
                            }) {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                if isPaused {
                                    speechSynthesizer.continueSpeaking()
                                } else {
                                    speechSynthesizer.pauseSpeaking(at: .immediate)
                                }
                                isPaused.toggle()
                            }) {
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                speechSynthesizer.stopSpeaking(at: .immediate)
                                isPaused = false
                            }) {
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                UIPasteboard.general.string = translatedText
                                showCopySuccessMessage = true
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                ScrollView {
                    Text(translatedText.isEmpty ? "Translation will appear here" : translatedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .foregroundColor(translatedText.isEmpty ? .gray : .primary)
                }
                .frame(height: 180)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .padding()
        .onAppear {
            // 检查 API Key
            if KeychainManager.shared.getAPIKey()?.isEmpty ?? true {
                showAPIKeySettings = true
            }
        }
        .sheet(isPresented: $showAPIKeySettings) {
            APIKeySettingsView(useCustomAPIKey: $useCustomAPIKey)
        }
        .alert("Copy Success", isPresented: $showCopySuccessMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Translation has been copied to clipboard")
        }
        .onChange(of: speechRecognizer.recognizedText) { newValue in
            handleSpeechRecognizedText()
        }
    }
    
    private func handleSpeechRecognizedText() {
        if !speechRecognizer.recognizedText.isEmpty {
            inputText = speechRecognizer.recognizedText
            // 重置识别的文本，避免重复
            speechRecognizer.recognizedText = ""
        }
    }
    
    private func speakText(_ text: String, language: String) {
        guard !text.isEmpty else { return }
        
        // 停止当前正在播放的语音
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        var languageCode = language
        
        // 如果是 Auto 模式，检测文本语言
        if language == "Auto" {
            languageCode = detectLanguage(text) ?? "English"
        }
        
        // 语言代码映射
        let languageMapping: [String: String] = [
            "English": "en-US",
            "Chinese": "zh-CN",
            "Japanese": "ja-JP",
            "Korean": "ko-KR",
            "French": "fr-FR",
            "German": "de-DE",
            "Spanish": "es-ES",
            "Russian": "ru-RU"
        ]
        
        // 获取对应的语言代码
        let speechLanguage = languageMapping[languageCode] ?? languageMapping[language] ?? "en-US"
        
        // 检查是否有可用的语音
        guard let voice = AVSpeechSynthesisVoice(language: speechLanguage) else {
            print("No voice available for language: \(speechLanguage)")
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    private func detectLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let languageCode = recognizer.dominantLanguage?.rawValue else { return nil }
        
        // 将语言代码转换为语言名称
        let languageMapping: [String: String] = [
            "en": "English",
            "zh": "Chinese",
            "ja": "Japanese",
            "ko": "Korean",
            "fr": "French",
            "de": "German",
            "es": "Spanish",
            "ru": "Russian"
        ]
        
        return languageMapping[String(languageCode.prefix(2))]
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("defaultSourceLanguage") private var defaultSourceLanguage = "Auto"
    @AppStorage("defaultTargetLanguage") private var defaultTargetLanguage = "English"
    @State private var showAPIKeySettings = false
    @Binding var useCustomAPIKey: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    
    let languages = ["Auto", "English", "Chinese", "Spanish", "French", "German", "Japanese", "Korean", "Russian", "Italian", "Portuguese"]
    
    var body: some View {
        Form {
            Section(header: Text("DEFAULT LANGUAGES")) {
                Picker("Source Language", selection: $defaultSourceLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                
                Picker("Target Language", selection: $defaultTargetLanguage) {
                    ForEach(languages.dropFirst(), id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
            }
            
            Section(header: Text("API SETTINGS")) {
                Toggle("Use Custom API Key", isOn: $useCustomAPIKey)
                    .onChange(of: useCustomAPIKey) { newValue in
                        if newValue && !KeychainManager.shared.hasCustomAPIKey() {
                            showAPIKeySettings = true
                        }
                    }
                
                HStack {
                    Text("API Key Status")
                    Spacer()
                    Text(useCustomAPIKey ? "Using Custom API Key" : "Using Default API Key")
                        .foregroundColor(.gray)
                }
                
                if useCustomAPIKey {
                    Button("Set API Key", action: {
                        showAPIKeySettings = true
                    })
                    .foregroundColor(.blue)
                }
            }
            
            Section(header: Text("APPEARANCE")) {
                Toggle("Dark Mode", isOn: Binding(
                    get: { themeManager.colorScheme == .dark },
                    set: { themeManager.setTheme($0) }
                ))
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showAPIKeySettings) {
            APIKeySettingsView(useCustomAPIKey: $useCustomAPIKey)
        }
    }
}

// MARK: - API Key Settings View
struct APIKeySettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var useCustomAPIKey: Bool
    @State private var apiKey: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("OpenAI API Key")
                    .font(.headline)
                
                SecureField("Enter API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Save API Key") {
                    if KeychainManager.shared.saveAPIKey(apiKey) {
                        alertTitle = "Success"
                        alertMessage = "API Key saved successfully"
                        useCustomAPIKey = true
                        showAlert = true
                    } else {
                        alertTitle = "Error"
                        alertMessage = "Failed to save API Key"
                        showAlert = true
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if KeychainManager.shared.hasCustomAPIKey() {
                    Button("Clear API Key") {
                        apiKey = ""
                        if KeychainManager.shared.deleteAPIKey() {
                            alertTitle = "Success"
                            alertMessage = "API Key cleared successfully"
                            useCustomAPIKey = false
                            showAlert = true
                        } else {
                            alertTitle = "Error"
                            alertMessage = "Failed to clear API Key"
                            showAlert = true
                        }
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("API Key Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertTitle == "Success" {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .onAppear {
                if KeychainManager.shared.hasCustomAPIKey(),
                   let savedKey = KeychainManager.shared.getAPIKey() {
                    apiKey = savedKey
                }
            }
        }
    }
}
