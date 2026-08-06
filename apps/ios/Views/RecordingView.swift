import SwiftUI

struct RecordingView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.red.opacity(0.12))
                    .frame(width: 150, height: 150)
                Circle()
                    .fill(.red.opacity(0.2 + Double(model.recorder.audioLevel) * 0.35))
                    .frame(width: 88 + CGFloat(model.recorder.audioLevel) * 28, height: 88 + CGFloat(model.recorder.audioLevel) * 28)
                Image(systemName: "waveform")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.red)
            }

            Text("Aufnahme läuft")
                .font(.title2.bold())
            Text(formatDuration(model.recorder.elapsed))
                .font(.system(.title, design: .monospaced).weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Maximal 5 Minuten")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
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
        .padding(.vertical, 20)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
