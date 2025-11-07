import SwiftUI

struct AudioRecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recorder = AudioRecorder()
    @State private var hasPermission = false
    @State private var showPermissionAlert = false
    
    let onFinished: (URL?) -> Void
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            VStack(spacing: 32) {
                HStack {
                    Button("< Back") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .tint(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                
                Text("Audio Recording")
                    .font(.title2.bold())
                    .padding(.top, 16)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.85))
                        .frame(width: 240, height: 240)
                        .shadow(radius: 12)
                    VStack(spacing: 12) {
                        Image(systemName: recorder.isRecording ? "record.circle" : "mic")
                            .font(.system(size: recorder.isRecording ? 80 : 70, weight: .semibold))
                            .foregroundColor(recorder.isRecording ? .red : .white)
                        Text(timeString(recorder.elapsed))
                            .font(.title3.monospacedDigit())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 16)
                
                Button(action: toggleRecording) {
                    Text(recorder.isRecording ? "Stop" : "Tap to Record")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(recorder.isRecording ? .red : .green)
                .padding(.horizontal)
                
                if let url = recorder.recordedURL, !recorder.isRecording {
                    Button {
                        onFinished(url)
                        dismiss()
                    } label: {
                        Text("Use This Recording")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .onAppear { requestAccess() }
        .alert("Microphone permission required", isPresented: $showPermissionAlert) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text("Please enable microphone access in Settings to record audio.")
        }
    }
    
    private func requestAccess() {
        Task {
            do {
                try await recorder.requestPermission()
                hasPermission = true
            } catch {
                showPermissionAlert = true
            }
        }
    }
    
    private func toggleRecording() {
        guard hasPermission else {
            showPermissionAlert = true
            return
        }
        if recorder.isRecording {
            recorder.stop()
        } else {
            do {
                try recorder.start()
            } catch {
                print("Recording failed: \(error)")
            }
        }
    }
    
    private func timeString(_ time: TimeInterval) -> String {
        if time.isNaN || time.isInfinite { return "00:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


