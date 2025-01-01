import Foundation
import SwiftUI
import KeychainAccess
import Speech
import AVFoundation

public protocol SpeechRecognitionService: ObservableObject {
    var recognizedText: String { get set }
    var isRecording: Bool { get set }
    var errorMessage: String? { get set }
    
    func startRecording(language: String) async throws
    func stopRecording()
}

#if os(iOS)
public final class SpeechRecognitionManager: NSObject, SpeechRecognitionService, ObservableObject {
    @Published public var recognizedText: String = ""
    @Published public var isRecording: Bool = false
    @Published public var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    public override init() {
        super.init()
    }
    
    public func requestAuthorization() async throws {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        guard status == .authorized else {
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition authorization denied"])
        }
    }
    
    public func startRecording(language: String) async throws {
        let locale = Locale(identifier: mapLanguageToLocale(language))
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available"])
        }
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        audioEngine = AVAudioEngine()
        
        guard let recognitionRequest = recognitionRequest,
              let audioEngine = audioEngine else {
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request or audio engine"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.stopRecording()
            }
        }
    }
    
    public func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    private func mapLanguageToLocale(_ language: String) -> String {
        switch language.lowercased() {
        case "english": return "en-US"
        case "chinese": return "zh-CN"
        case "japanese": return "ja-JP"
        case "korean": return "ko-KR"
        case "spanish": return "es-ES"
        case "french": return "fr-FR"
        case "german": return "de-DE"
        case "auto": return Locale.current.identifier
        default: return language
        }
    }
}
#endif

public protocol TranslationServiceProtocol: ObservableObject {
    var useCustomAPIKey: Bool { get set }
    var apiKey: String { get set }
    func translate(text: String, from: String, to: String) async throws -> String
    func saveAPIKey(_ key: String) throws
    func loadAPIKey() throws -> String?
}

public extension TranslationServiceProtocol {
    func mapLanguageToLocale(_ language: String) -> String {
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
