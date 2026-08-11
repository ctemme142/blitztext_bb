import SwiftUI

struct MainView: View {
    @ObservedObject var model: AppModel
    @State private var isEditingResult = false
    @FocusState private var isResultEditorFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .recording:
                    RecordingView(model: model, recorder: model.recorder)
                        .padding(.horizontal, 20)
                case .finished:
                    resultView
                        .padding(16)
                default:
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            header
                            workflowPicker

                            switch model.state {
                            case .idle:
                                idleView
                            case .recording:
                                EmptyView()
                            case .processing(let text):
                                processingView(text)
                            case .finished:
                                EmptyView()
                            case .failed(let message):
                                failureView(message)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Blitztext")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(isEditingResult ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Einstellungen")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Bearbeitung beenden") {
                        endResultEditing()
                    }
                }
            }
            .sheet(isPresented: $model.showingSettings) {
                SettingsView(model: model)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Sprich los.")
                .font(.title2.bold())
            Text(model.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var workflowPicker: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Workflow")
                .font(.subheadline.weight(.semibold))
            Picker("Workflow", selection: $model.selectedWorkflow) {
                ForEach(WorkflowType.allCases) { workflow in
                    Label(workflow.displayName, systemImage: workflow.systemImage)
                        .tag(workflow)
                }
            }
            .pickerStyle(.menu)
            .disabled(model.isBusy)
            Text(model.selectedWorkflow.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var idleView: some View {
        VStack(spacing: 10) {
            Image(systemName: model.selectedWorkflow.systemImage)
                .font(.system(size: 30))
                .foregroundStyle(.blue)
            Text("Bereit für eine neue Aufnahme")
                .font(.subheadline.weight(.semibold))
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
        .padding(.vertical, 12)
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
        VStack(alignment: .leading, spacing: 10) {
            if isEditingResult {
                HStack {
                    Label("Text bearbeiten", systemImage: "pencil")
                        .font(.headline)
                    Spacer()
                    Button("Übernehmen") {
                        endResultEditing()
                    }
                    .buttonStyle(.borderedProminent)
                }

                TextEditor(text: Binding(
                    get: { model.resultText },
                    set: { value in
                        model.resultText = value
                        model.markResultEdited()
                    }
                ))
                .font(.body)
                .focused($isResultEditorFocused)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            } else {
                HStack {
                    Label("Ergebnis", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                    Spacer()
                    Text(model.statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                Group {
                    ScrollView {
                        Text(model.resultText)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

                if model.showingOriginal {
                    ScrollView {
                        Text(model.rawText)
                            .font(.subheadline)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 100)
                    .padding(8)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                }

                HStack {
                    Button {
                        model.copyResult()
                    } label: {
                        Label("Kopieren", systemImage: "doc.on.doc")
                    }
                        .buttonStyle(.borderedProminent)
                    Button {
                        beginResultEditing()
                    } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    if model.selectedWorkflow != .transcription {
                        Button(model.showingOriginal ? "Original ausblenden" : "Original anzeigen") {
                            model.showingOriginal.toggle()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                HStack {
                    Button {
                        model.startRecording()
                    } label: {
                        Label("Aufnehmen", systemImage: "mic.fill")
                    }
                        .buttonStyle(.bordered)
                    ShareLink(item: model.resultText) {
                        Label("Teilen ...", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func beginResultEditing() {
        isEditingResult = true
        Task { @MainActor in
            await Task.yield()
            isResultEditorFocused = true
        }
    }

    private func endResultEditing() {
        isResultEditorFocused = false
        isEditingResult = false
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
