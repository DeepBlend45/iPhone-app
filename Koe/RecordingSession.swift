import AVFoundation
import Speech
import Observation

/// 録音 → 端末内での文字起こし までを担当する
@Observable @MainActor
final class RecordingSession {
    enum Phase: Equatable {
        case idle, recording, transcribing, finished
        case failed(String)
    }

    var phase: Phase = .idle
    var transcript = ""
    private(set) var audioFileName: String?
    private var recorder: AVAudioRecorder?

    func start() async {
        guard await requestPermissions() else {
            phase = .failed("マイクと音声認識の許可が必要です（設定アプリから許可してください）")
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let name = UUID().uuidString + ".m4a"
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
            ]
            let recorder = try AVAudioRecorder(url: AudioStore.url(for: name), settings: settings)
            recorder.record()
            self.recorder = recorder
            audioFileName = name
            phase = .recording
        } catch {
            phase = .failed("録音を開始できませんでした: \(error.localizedDescription)")
        }
    }

    func stop() async {
        recorder?.stop()
        recorder = nil
        guard let name = audioFileName else { return }
        phase = .transcribing
        do {
            transcript = try await Self.transcribe(url: AudioStore.url(for: name))
            phase = .finished
        } catch {
            // 文字起こしに失敗しても音声は残す。手入力で補えるようにする
            transcript = ""
            phase = .failed("文字起こしに失敗しました（音声は保存済み）: \(error.localizedDescription)")
        }
    }

    private func requestPermissions() async -> Bool {
        let mic = await AVAudioApplication.requestRecordPermission()
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        return mic && speech
    }

    private static func transcribe(url: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP")),
              recognizer.isAvailable else {
            throw NSError(domain: "Koe", code: 1, userInfo: [NSLocalizedDescriptionKey: "音声認識を利用できません"])
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true   // 音声を端末の外に出さない
        request.addsPunctuation = true

        return try await withCheckedThrowingContinuation { continuation in
            var finished = false
            recognizer.recognitionTask(with: request) { result, error in
                guard !finished else { return }
                if let result, result.isFinal {
                    finished = true
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if let error {
                    finished = true
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
