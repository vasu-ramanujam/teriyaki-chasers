import SwiftUI
import AVFoundation

struct AudioPlaybackView: View {
    let url: URL
    
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 12) {
            Slider(value: Binding(
                get: { duration == 0 ? 0 : progress / duration },
                set: { newValue in
                    guard let player else { return }
                    let newTime = newValue * player.duration
                    player.currentTime = newTime
                    progress = newTime
                }
            ))
            .tint(.green)
            .disabled(player == nil)
            
            HStack(spacing: 16) {
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .padding(12)
                        .background(Color(.systemGreen).opacity(0.15))
                        .clipShape(Circle())
                }
                .disabled(player == nil)
                
                Text(timeString(progress))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .onAppear { preparePlayer() }
        .onDisappear { cleanup() }
    }
    
    private func preparePlayer() {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
        } catch {
            print("Audio playback error: \(error)")
        }
    }
    
    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            stopTimer()
            isPlaying = false
        } else {
            player.play()
            startTimer()
            isPlaying = true
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let player else { return }
            progress = player.currentTime
            if !player.isPlaying {
                isPlaying = false
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func cleanup() {
        stopTimer()
        player?.stop()
        player = nil
    }
    
    private func timeString(_ time: TimeInterval) -> String {
        guard !time.isNaN else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


