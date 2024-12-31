import Foundation
import Speech
import AVFoundation
import SwiftUI
import Combine

class SpeechRecognitionManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    @Published var isAuthorized = false
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        
        guard speechRecognizer?.isAvailable == true else {
            DispatchQueue.main.async {
                self.errorMessage = "Speech recognition is not available"
            }
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch authStatus {
                case .authorized:
                    self.isAuthorized = true
                    self.errorMessage = nil
                case .denied:
                    self.isAuthorized = false
                    self.errorMessage = "用户拒绝了语音识别权限"
                case .restricted:
                    self.isAuthorized = false
                    self.errorMessage = "语音识别在此设备上受限"
                case .notDetermined:
                    self.isAuthorized = false
                    self.errorMessage = "语音识别未获得授权"
                @unknown default:
                    self.isAuthorized = false
                    self.errorMessage = "未知错误"
                }
            }
        }
    }
    
    func startRecording() {
        DispatchQueue.main.async {
            guard self.isAuthorized else {
                self.errorMessage = "请先授权语音识别权限"
                return
            }
            
            guard !self.isRecording else { return }
            
            // 重置之前的任务
            if let recognitionTask = self.recognitionTask {
                recognitionTask.cancel()
                self.recognitionTask = nil
            }
            
            // 请求麦克风权限
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if !allowed {
                        self.errorMessage = "请先授权麦克风权限"
                        return
                    }
                    
                    self.startRecordingWithPermission()
                }
            }
        }
    }
    
    private func startRecordingWithPermission() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "无法创建语音识别请求"
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.stopRecording()
                        return
                    }
                    
                    if let result = result {
                        self.recognizedText = result.bestTranscription.formattedString
                    }
                    
                    if result?.isFinal == true {
                        self.stopRecording()
                    }
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.errorMessage = nil
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func stopRecording() {
        DispatchQueue.main.async {
            self.audioEngine.stop()
            self.audioEngine.inputNode.removeTap(onBus: 0)
            self.recognitionRequest?.endAudio()
            self.recognitionRequest = nil
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            self.isRecording = false
        }
    }
}
