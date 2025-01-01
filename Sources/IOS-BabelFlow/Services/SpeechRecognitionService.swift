import Foundation
import SwiftUI

@available(macOS 10.15, *)
public protocol SpeechRecognitionService: ObservableObject {
    var isRecording: Bool { get set }
    func startRecording(completion: @escaping (String) -> Void)
    func stopRecording()
}
