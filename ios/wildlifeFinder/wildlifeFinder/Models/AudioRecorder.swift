import Foundation
import AVFoundation
import Observation

@Observable
final class AudioRecorder: NSObject {
    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private var timer: Timer?
    
    var isRecording = false
    var recordedURL: URL?
    var elapsed: TimeInterval = 0
    
    func requestPermission() async throws {
        try await withCheckedThrowingContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted { cont.resume() } else { cont.resume(throwing: NSError(domain: "mic", code: 1)) }
            }
        }
    }
    
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        let tmp = FileManager.default.temporaryDirectory
        let url = tmp.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.prepareToRecord()
        recorder?.record()
        recordedURL = url
        elapsed = 0
        isRecording = true
        startTimer()
    }
    
    func stop() {
        recorder?.stop()
        recorder = nil
        stopTimer()
        isRecording = false
        deactivateSession()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let recorder else { return }
            self.elapsed = recorder.currentTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func deactivateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session deactivate error: \(error)")
        }
    }
}


