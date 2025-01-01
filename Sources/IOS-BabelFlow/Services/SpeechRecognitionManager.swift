@available(macOS 10.15, *)
@MainActor
public class SpeechRecognitionManager: NSObject, ObservableObject, AVAudioRecorderDelegate, SFSpeechRecognizerDelegate {
    @Published public var isRecording = false
    @Published public var currentLocaleIdentifier: String = "zh-CN"
    @Published public var errorMessage: String?
    @Published public var audioLevel: Float = 0.0
    @Published public var recordingState: String = "Ready"
    
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioBufferRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognizer: SFSpeechRecognizer?
    private var levelTimer: Timer?
    private var retryCount = 0
    private let maxRetries = 3
    
    private var chineseRecognizer: SFSpeechRecognizer?
    private var englishRecognizer: SFSpeechRecognizer?
    
    public override init() {
        super.init()
        setupRecognizers()
        setupAudioSession()
    }
    
    private func setupRecognizers() {
        // 初始化中文识别器
        chineseRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))
        chineseRecognizer?.delegate = self
        
        // 初始化英文识别器作为备份
        englishRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
        englishRecognizer?.delegate = self
        
        // 默认使用中文识别器
        recognizer = chineseRecognizer
        
        Task {
            await requestAuthorization()
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "音频设置初始化失败: \(error.localizedDescription)"
            recordingState = "Error"
        }
    }
    
    private func requestAuthorization() async {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        switch status {
        case .authorized:
            break
        case .denied:
            errorMessage = "请在设置中允许语音识别权限"
            recordingState = "Error"
        case .restricted:
            errorMessage = "设备不支持语音识别"
            recordingState = "Error"
        case .notDetermined:
            errorMessage = "语音识别权限未确定"
            recordingState = "Error"
        @unknown default:
            errorMessage = "未知错误"
            recordingState = "Error"
        }
    }
    
    public func startRecording(completion: @escaping (String) -> Void) {
        guard !isRecording else { return }
        
        // 重置状态
        retryCount = 0
        errorMessage = nil
        
        // 确保使用中文识别器
        recognizer = chineseRecognizer
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            errorMessage = "语音识别服务不可用"
            recordingState = "Error"
            return
        }
        
        // 开始录音和识别
        startRecordingWithRetry(completion: completion)
    }
    
    private func startRecordingWithRetry(completion: @escaping (String) -> Void) {
        Task { @MainActor in
            do {
                // 配置音频引擎
                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                
                // 创建识别请求
                audioBufferRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let request = audioBufferRequest else {
                    throw NSError(domain: "SpeechRecognitionError", code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "无法创建识别请求"])
                }
                
                // 配置识别选项
                request.shouldReportPartialResults = true
                request.taskHint = .dictation
                if #available(iOS 13, *) {
                    request.requiresOnDeviceRecognition = false
                }
                
                // 设置音频输入
                inputNode.removeTap(onBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                    self?.audioBufferRequest?.append(buffer)
                }
                
                // 启动音频引擎
                audioEngine.prepare()
                try audioEngine.start()
                
                // 开始识别
                recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Recognition error: \(error)")  // 调试日志
                        self.handleRecognitionError(error, completion: completion)
                        return
                    }
                    
                    if let result = result {
                        let transcription = result.bestTranscription.formattedString
                        if !transcription.isEmpty {
                            print("Recognized text: \(transcription)")  // 调试日志
                            Task { @MainActor in
                                completion(transcription)
                            }
                        }
                    }
                }
                
                isRecording = true
                recordingState = "Recording"
                startMonitoringAudioLevel()
                
            } catch {
                print("Setup error: \(error)")  // 调试日志
                handleRecognitionError(error, completion: completion)
            }
        }
    }
    
    private func handleRecognitionError(_ error: Error, completion: @escaping (String) -> Void) {
        Task { @MainActor in
            if retryCount < maxRetries {
                retryCount += 1
                errorMessage = "识别失败，正在重试 (\(retryCount)/\(maxRetries))"
                
                // 重置音频引擎
                audioEngine.stop()
                audioEngine.reset()
                
                // 延迟后重试
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                startRecordingWithRetry(completion: completion)
            } else {
                errorMessage = "语音识别失败: \(error.localizedDescription)"
                recordingState = "Error"
                stopRecording()
            }
        }
    }
    
    private func startMonitoringAudioLevel() {
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let inputNode = self.audioEngine.inputNode
            let level = inputNode.volume
            
            Task { @MainActor in
                self.audioLevel = level
            }
        }
    }
    
    public func stopRecording() {
        guard isRecording else { return }
        
        print("Stopping recording...")  // 调试日志
        
        levelTimer?.invalidate()
        levelTimer = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        audioBufferRequest = nil
        isRecording = false
        recordingState = "Stopped"
        
        // 重置音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")  // 调试日志
            errorMessage = "停止录音失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            errorMessage = "语音识别服务暂时不可用"
            recordingState = "Error"
        }
    }
}
