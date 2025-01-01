# BabelFlow 开发文档

## 1. 项目概述

BabelFlow 是一款基于 iOS 平台的智能语音翻译应用，旨在为用户提供便捷、准确的多语言翻译服务。本应用利用先进的 AI 技术，支持实时语音识别和翻译功能，帮助用户突破语言障碍，实现无障碍沟通。

## 2. 需求分析

### 2.1 功能需求

#### 2.1.1 多语言文本翻译

- **语言支持**：至少支持以下10种常用语言：
  - 英语（English）
  - 中文（Chinese）
  - 西班牙语（Spanish）
  - 法语（French）
  - 德语（German）
  - 日语（Japanese）
  - 韩语（Korean）
  - 俄语（Russian）
  - 意大利语（Italian）
  - 葡萄牙语（Portuguese）

- **语言选择**：
  - 使用下拉菜单或滚动选择器供用户选择语言
  - 显示语言名称和国旗图标
  - 支持自动检测源语言
  - 提供一键切换源语言和目标语言功能

- **文本处理**：
  - 多行文本输入框
  - 支持复制和粘贴
  - 清空文本功能
  - 复制翻译结果
  - 语音朗读功能

#### 2.1.2 语音翻译功能

- **语音输入**：
  - 支持实时语音录入，提供高质量音频采集
  - 显示实时音量波形反馈
  - 智能检测语音停顿，自动结束录音
  - 支持长按说话或点击开始/结束录音两种模式
  - 录音时显示剩余可录制时间

- **语音识别**：
  - 使用 Apple Speech Framework 进行实时语音识别
  - 支持所有主流语言的语音识别
  - 实时显示识别结果，支持动态更新
  - 提供识别准确度指示
  - 允许用户手动编辑识别结果

- **语音翻译**：
  - 集成 OpenAI API 进行高质量翻译
  - 支持识别结果的实时翻译
  - 保持原文语气和语境
  - 支持专业术语和俚语翻译

- **语音合成**：
  - 支持翻译结果的语音朗读
  - 提供多种发音人选择
  - 支持语速和音量调节
  - 朗读时提供进度显示

### 2.2 性能需求

- **响应时间**：
  - 语音识别响应时间 < 1秒
  - 翻译结果返回时间 < 2秒
  - 界面切换流畅，无卡顿

- **准确性**：
  - 语音识别准确率 > 95%
  - 翻译结果符合语境要求
  - 支持专业术语翻译

### 2.3 非功能需求

- **安全性**：
  - 用户 API 密钥安全存储
  - 数据传输加密
  - 隐私保护措施

- **可用性**：
  - 离线功能支持
  - 错误提示友好
  - 操作步骤简单

- **可维护性**：
  - 模块化设计
  - 代码规范统一
  - 日志记录完善

## 3. 技术实现

### 3.1 技术栈
- iOS 15.0+
- SwiftUI
- OpenAI API
- AVFoundation (语音录制)
- Speech Framework (语音识别)
- KeychainSwift (安全存储)

### 3.2 项目结构
```
IOS-BabelFlow/
├── App/
│   ├── IOS_BabelFlowApp.swift    # 应用入口
│   └── ThemeManager.swift        # 主题管理
├── Views/
│   ├── ContentView.swift         # 主视图
│   ├── TranslationView.swift     # 翻译视图
│   ├── SettingsView.swift        # 设置视图
│   └── Components/              # 可复用组件
├── Models/
│   └── TranslationService.swift  # 翻译服务
├── Utils/
│   └── KeychainManager.swift     # 密钥管理
└── Resources/                    # 资源文件
```

### 3.3 核心功能实现

#### 2.1.1 语音翻译功能

```swift
class AudioManager: ObservableObject {
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode
    private var audioBuffer: AVAudioPCMBuffer?
    
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    
    init() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .spokenAudio, options: .defaultToSpeaker)
        try? session.setActive(true)
    }
    
    func startRecording() {
        let format = inputNode.outputFormat(forBus: 0)
        
        // 设置音频缓冲区
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isRecording = true
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // 计算音量级别
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = UInt32(buffer.frameLength)
        
        var sum: Float = 0
        for frame in 0..<Int(frames) {
            sum += abs(channelData[frame])
        }
        
        let average = sum / Float(frames)
        DispatchQueue.main.async {
            self.audioLevel = average * 10
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isRecording = false
    }
}
```

#### 2.1.2 实时语音识别

```swift
class SpeechRecognitionManager: ObservableObject {
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var transcript = ""
    @Published var isFinal = false
    @Published var confidence: Float = 0.0
    
    init(locale: Locale = .current) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)!
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition authorization denied")
                case .restricted:
                    print("Speech recognition restricted")
                case .notDetermined:
                    print("Speech recognition not determined")
                @unknown default:
                    print("Unknown authorization status")
                }
            }
        }
    }
    
    func startRecognition(audioEngine: AVAudioEngine) {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.transcript = result.bestTranscription.formattedString
                self.confidence = result.bestTranscription.segments.last?.confidence ?? 0.0
                self.isFinal = result.isFinal
            }
        }
        
        let format = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }
    }
    
    func stopRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}
```

#### 2.1.3 语音合成

```swift
class SpeechSynthesizer: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var progress: Float = 0.0
    
    init() {
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, language: String, rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let progress = Float(characterRange.location + characterRange.length) / Float(utterance.speechString.count)
        self.progress = progress
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        progress = 0.0
    }
}
```

#### 2.1.4 翻译历史管理

```swift
struct TranslationRecord: Codable, Identifiable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let sourceLang: String
    let targetLang: String
    let timestamp: Date
    var isFavorite: Bool
}

class TranslationHistoryManager: ObservableObject {
    @Published var records: [TranslationRecord] = []
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadHistory()
    }
    
    func addRecord(_ record: TranslationRecord) {
        records.insert(record, at: 0)
        saveHistory()
    }
    
    func toggleFavorite(_ id: UUID) {
        if let index = records.firstIndex(where: { $record.id == id }) {
            records[index].isFavorite.toggle()
            saveHistory()
        }
    }
    
    func searchHistory(_ query: String) -> [TranslationRecord] {
        records.filter { record in
            record.sourceText.localizedCaseInsensitiveContains(query) ||
            record.translatedText.localizedCaseInsensitiveContains(query)
        }
    }
    
    private func loadHistory() {
        if let data = userDefaults.data(forKey: "translationHistory"),
           let decoded = try? JSONDecoder().decode([TranslationRecord].self, from: data) {
            records = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(records) {
            userDefaults.set(encoded, forKey: "translationHistory")
        }
    }
}
```

### 2.2 用户界面实现

#### 2.2.1 翻译视图

```swift
struct TranslationView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var speechRecognitionManager = SpeechRecognitionManager()
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @StateObject private var translationHistoryManager = TranslationHistoryManager()
    
    @State private var translatedText = ""
    @State private var isRecording = false
    
    var body: some View {
        VStack {
            // 语音输入按钮
            Button(action: {
                if isRecording {
                    audioManager.stopRecording()
                    speechRecognitionManager.stopRecognition()
                } else {
                    audioManager.startRecording()
                    speechRecognitionManager.startRecognition(audioEngine: audioManager.audioEngine)
                    isRecording = true
                }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(isRecording ? .red : .blue)
            }
            
            // 识别结果显示
            Text(speechRecognitionManager.transcript)
                .padding()
            
            // 翻译结果显示
            Text(translatedText)
                .padding()
            
            // 翻译历史按钮
            Button(action: {
                // 展示翻译历史
            }) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
            }
        }
    }
}
```

## 4. 性能优化

### 4.1 录音优化
- 使用适当的音频格式和采样率
- 实现噪音消除
- 优化文件大小

### 4.2 识别优化
- 支持实时识别
- 实现错误重试机制
- 添加识别超时处理

### 4.3 翻译优化
- 实现请求缓存
- 添加失败重试机制
- 优化响应处理

## 5. 安全考虑

### 5.1 API 密钥管理
- 使用 Keychain 安全存储
- 实现密钥验证机制
- 提供密钥重置功能

### 5.2 数据安全
- 实现数据加密存储
- 清理临时文件
- 保护用户隐私

## 6. 测试策略

### 6.1 单元测试
- 测试录音功能
- 测试识别准确性
- 测试翻译质量

### 6.2 集成测试
- 测试完整翻译流程
- 测试错误处理
- 测试性能指标

## 7. 发布流程

### 7.1 版本控制
- 使用语义化版本
- 维护更新日志
- 标记重要版本

### 7.2 发布检查清单
- 代码审查完成
- 测试用例通过
- 文档更新完成
- 性能指标达标
