import Foundation
import ComposableArchitecture

#if os(iOS) && canImport(AVFoundation) && canImport(Speech)
import AVFoundation
import Speech
#endif

public struct VoiceInputClient: Sendable {
    public var recognize: @Sendable () async throws -> String

    public init(
        recognize: @escaping @Sendable () async throws -> String
    ) {
        self.recognize = recognize
    }
}

public extension VoiceInputClient {
    static let noop = VoiceInputClient(
        recognize: { "" }
    )

    static let live = VoiceInputClient(
        recognize: {
            #if os(iOS) && canImport(AVFoundation) && canImport(Speech)
            return try await SpeechRecognitionSession().recognizeOnce()
            #else
            throw VoiceInputClientError.unavailable
            #endif
        }
    )
}

private enum VoiceInputClientError: Error {
    case cancelled
    case emptyTranscript
    case permissionDenied
    case recognitionFailed
    case unavailable
}

#if os(iOS) && canImport(AVFoundation) && canImport(Speech)
@MainActor
private final class SpeechRecognitionSession {
    private let audioEngine = AVAudioEngine()
    private var continuation: CheckedContinuation<String, Error>?
    private var latestTranscript = ""
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var hasInstalledTap = false
    private var timeoutTask: Task<Void, Never>?

    func recognizeOnce() async throws -> String {
        guard await requestSpeechPermission(),
              await requestMicrophonePermission() else {
            throw VoiceInputClientError.permissionDenied
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation

                do {
                    try startRecognition()
                } catch {
                    finish(throwing: error)
                }
            }
        } onCancel: {
            Task { @MainActor in
                self.finish(throwing: VoiceInputClientError.cancelled)
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        if SFSpeechRecognizer.authorizationStatus() == .authorized {
            return true
        }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { isGranted in
                continuation.resume(returning: isGranted)
            }
        }
    }

    private func startRecognition() throws {
        guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi_VN")),
              speechRecognizer.isAvailable else {
            throw VoiceInputClientError.unavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: recordingFormat
        ) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        hasInstalledTap = true

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            let transcript = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let didFail = error != nil

            Task { @MainActor in
                self?.handleRecognitionUpdate(
                    transcript: transcript,
                    isFinal: isFinal,
                    didFail: didFail
                )
            }
        }

        timeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(6))
            finishWithLatestTranscriptOrTimeout()
        }
    }

    private func handleRecognitionUpdate(
        transcript: String?,
        isFinal: Bool,
        didFail: Bool
    ) {
        if let transcript,
           transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            latestTranscript = transcript
        }

        if isFinal {
            finishWithLatestTranscriptOrTimeout()
        } else if didFail {
            if latestTranscript.isEmpty {
                finish(throwing: VoiceInputClientError.recognitionFailed)
            } else {
                finish(returning: latestTranscript)
            }
        }
    }

    private func finishWithLatestTranscriptOrTimeout() {
        let transcript = latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if transcript.isEmpty {
            finish(throwing: VoiceInputClientError.emptyTranscript)
        } else {
            finish(returning: transcript)
        }
    }

    private func finish(returning transcript: String) {
        guard let continuation else {
            return
        }

        self.continuation = nil
        stopRecognition()
        continuation.resume(returning: transcript)
    }

    private func finish(throwing error: Error) {
        guard let continuation else {
            return
        }

        self.continuation = nil
        stopRecognition()
        continuation.resume(throwing: error)
    }

    private func stopRecognition() {
        timeoutTask?.cancel()
        timeoutTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }

        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: [.notifyOthersOnDeactivation]
        )
    }
}
#endif

private enum VoiceInputClientKey: DependencyKey {
    static let liveValue = VoiceInputClient.live
    static let previewValue = VoiceInputClient(
        recognize: { "Ăn sáng 40 nghìn" }
    )
    static let testValue = VoiceInputClient.noop
}

public extension DependencyValues {
    var voiceInputClient: VoiceInputClient {
        get { self[VoiceInputClientKey.self] }
        set { self[VoiceInputClientKey.self] = newValue }
    }
}
