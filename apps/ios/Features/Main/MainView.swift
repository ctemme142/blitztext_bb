import SwiftUI

struct MainView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    workflowPicker

                    switch model.state {
                    case .idle:
                        idleView
                    case .recording:
                        RecordingView(model: model, recorder: model.recorder)
                    case .processing(let text):
                        processingView(text)
                    case .finished:
                        resultView
                    case .failed(let message):
                        failureView(message)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Blitztext")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Einstellungen")
                }
            }
            .sheet(isPresented: $model.showingSettings) {
                SettingsView(model: model)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sprich los.")
                .font(.largeTitle.bold())
            Text(model.statusText)
                .foregroundStyle(.secondary)
        }
    }

    private var workflowPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workflow")
                .font(.headline)
            Picker("Workflow", selection: $model.selectedWorkflow) {
                ForEach(WorkflowType.allCases) { workflow in
                    Label(workflow.displayName, systemImage: workflow.systemImage)
                        .tag(workflow)
                }
            }
            .pickerStyle(.menu)
            .disabled(model.isBusy)
            Text(model.selectedWorkflow.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var idleView: some View {
        VStack(spacing: 16) {
            Image(systemName: model.selectedWorkflow.systemImage)
                .font(.system(size: 42))
                .foregroundStyle(.blue)
            Text("Bereit für eine neue Aufnahme")
                .font(.headline)
            Button {
                model.startRecording()
            } label: {
                Label("Aufnahme starten", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func processingView(_ text: String) -> some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text(text)
                .font(.headline)
            Text("Die Aufnahme bleibt bei einem Fehler für einen erneuten Versuch erhalten.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private var resultView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Fertig", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.headline)

            TextEditor(text: Binding(
                get: { model.resultText },
                set: { model.resultText = $0 }
            ))
            .frame(minHeight: 180)
            .padding(8)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))

            if model.showingOriginal {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Original")
                        .font(.headline)
                    Text(model.rawText)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
                }
            }

            HStack {
                Button("Kopieren") { model.copyResult() }
                    .buttonStyle(.borderedProminent)
                Button(model.showingOriginal ? "Original ausblenden" : "Original anzeigen") {
                    model.showingOriginal.toggle()
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Button("Neue Aufnahme") { model.startRecording() }
                    .buttonStyle(.bordered)
                Button("Fertig") { model.finishSession() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func failureView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Verarbeitung nicht abgeschlossen", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
            if model.hasRetryableAudio {
                Button("Erneut versuchen") { model.processPendingAudio() }
                    .buttonStyle(.borderedProminent)
                Button("Aufnahme verwerfen") { model.discardPendingAudio() }
                    .buttonStyle(.bordered)
            } else {
                Button("Neue Aufnahme") { model.startRecording() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
