import SwiftUI

struct RecordingView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var recorder: AudioRecorder

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.red.opacity(0.12))
                    .frame(width: 112, height: 112)
                Circle()
                    .fill(.red.opacity(0.2 + Double(recorder.audioLevel) * 0.35))
                    .frame(width: 68 + CGFloat(recorder.audioLevel) * 20, height: 68 + CGFloat(recorder.audioLevel) * 20)
                Image(systemName: "waveform")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.red)
            }

            Text("Aufnahme läuft")
                .font(.title3.bold())
            Text(formatDuration(recorder.elapsed))
                .font(.system(.title2, design: .monospaced).weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Maximal 5 Minuten")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Button {
                    model.finishRecording()
                } label: {
                    Label("Aufnahme beenden", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)

                Button("Abbrechen") {
                    model.cancelRecording()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
