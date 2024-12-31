import Foundation
import Speech
import AVFoundation

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
        speechRecognizer = SFSpeechRecognizer()
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.errorMessage = nil
                case .denied:
                    self?.errorMessage = "用户拒绝了语音识别权限"
                case .restricted:
                    self?.errorMessage = "语音识别在此设备上受限"
                case .notDetermined:
                    self?.errorMessage = "语音识别未获得授权"
                @unknown default:
                    self?.errorMessage = "未知错误"
                }
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // 重置之前的任务
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // 设置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "设置音频会话失败: \(error.localizedDescription)"
            return
        }
        
        // 创建并配置识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "无法创建语音识别请求"
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // 配置音频引擎和识别任务
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
            
            if result?.isFinal == true {
                self.stopRecording()
            }
        }
        
        // 安装音频tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // 启动音频引擎
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = "启动音频引擎失败: \(error.localizedDescription)"
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        recognitionRequest = nil
        recognitionTask = nil
        
        // 重置音频会话
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
