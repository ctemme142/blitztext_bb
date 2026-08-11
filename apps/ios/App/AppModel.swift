import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    nonisolated static let shortcutLaunchKey = "blitztext.startFromShortcut"
    private static let setupCompleteKey = "blitztext.setupComplete"
    private static let lastWorkflowKey = "blitztext.lastWorkflow"

    @Published var selectedWorkflow: WorkflowType {
        didSet {
            UserDefaults.standard.set(selectedWorkflow.rawValue, forKey: Self.lastWorkflowKey)
        }
    }
    @Published private(set) var state: ProcessingState = .idle
    @Published private(set) var statusText = "Bereit für die nächste Aufnahme."
    @Published var resultText = ""
    @Published private(set) var rawText = ""
    @Published private(set) var isSetupComplete: Bool
    @Published var showingSettings = false
    @Published var showingOriginal = false

    let recorder = AudioRecorder()
    private var pendingAudioURL: URL?
    private var processingTask: Task<Void, Never>?
    private var isStartingRecording = false

    private init() {
        let rawWorkflow = UserDefaults.standard.string(forKey: Self.lastWorkflowKey)
        selectedWorkflow = WorkflowType(rawValue: rawWorkflow ?? "") ?? .transcription
        isSetupComplete = UserDefaults.standard.bool(forKey: Self.setupCompleteKey) && KeychainService.hasAPIKey
        recorder.onTimeLimitReached = { [weak self] in
            self?.finishRecording()
        }
        recorder.onInterruption = { [weak self] in
            self?.finishRecording(interrupted: true)
        }
    }

    var isBusy: Bool {
        switch state {
        case .recording, .processing: return true
        default: return false
        }
    }

    var hasResult: Bool { !resultText.isEmpty }
    var hasRetryableAudio: Bool { pendingAudioURL != nil }

    func completeSetup(with apiKey: String) async -> String? {
        do {
            try await OpenAIService.validateAPIKey(apiKey)
            try KeychainService.saveAPIKey(apiKey)
            UserDefaults.standard.set(true, forKey: Self.setupCompleteKey)
            isSetupComplete = true
            return nil
        } catch {
            return errorMessage(for: error)
        }
    }

    func changeAPIKey(_ apiKey: String) async -> String? {
        do {
            try await OpenAIService.validateAPIKey(apiKey)
            try KeychainService.saveAPIKey(apiKey)
            isSetupComplete = true
            return nil
        } catch {
            return errorMessage(for: error)
        }
    }

    func deleteAPIKey() {
        try? KeychainService.deleteAPIKey()
        UserDefaults.standard.set(false, forKey: Self.setupCompleteKey)
        isSetupComplete = false
    }

    func startRecording() {
        guard isSetupComplete, !isBusy, !isStartingRecording else { return }
        resultText = ""
        rawText = ""
        showingOriginal = false
        pendingAudioURL = nil
        isStartingRecording = true
        state = .processing("Aufnahme wird gestartet ...")
        statusText = "Aufnahme wird gestartet ..."
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await recorder.start()
                isStartingRecording = false
                state = .recording
                statusText = "Aufnahme läuft ..."
            } catch {
                isStartingRecording = false
                state = .failed(errorMessage(for: error))
                statusText = "Die Aufnahme konnte nicht gestartet werden."
            }
        }
    }

    func finishRecording(interrupted: Bool = false) {
        guard state == .recording else { return }
        pendingAudioURL = recorder.stop()
        guard pendingAudioURL != nil else {
            state = .failed("iOS hat keine Audiodatei erzeugt. Bitte prüfen Sie in den iPhone-Einstellungen unter Datenschutz & Sicherheit > Mikrofon, ob Blitztext Zugriff hat. Diagnose: (recorder.diagnostic)")
            statusText = "Keine Audiodatei vorhanden."
            return
        }
        if interrupted {
            state = .failed("Die Aufnahme wurde durch eine Unterbrechung beendet.")
            statusText = "Die Aufnahme wurde beendet. Sie können sie erneut verarbeiten."
            return
        }
        statusText = "Aufnahme beendet. Transkription wird gestartet ..."
        processPendingAudio()
    }

    func cancelRecording() {
        guard state == .recording else { return }
        recorder.cancel()
        pendingAudioURL = nil
        state = .idle
        statusText = "Aufnahme verworfen."
    }

    func processPendingAudio() {
        guard let audioURL = pendingAudioURL, !isBusy else { return }
        state = .processing("Wird transkribiert ...")
        statusText = "Wird transkribiert ..."
        processingTask?.cancel()
        processingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let transcript = try await OpenAIService.transcribe(audioURL: audioURL)
                rawText = transcript
                state = .processing(selectedWorkflow == .transcription ? "Text wird vorbereitet ..." : "Text wird verarbeitet ...")
                statusText = state.processingText ?? "Text wird verarbeitet ..."
                let finalText = try await OpenAIService.rewrite(transcript, for: selectedWorkflow)
                resultText = finalText
                state = .finished
                statusText = "Fertig. Der Text wurde kopiert."
                UIPasteboard.general.string = finalText
                deletePendingAudio()
            } catch {
                state = .failed(errorMessage(for: error))
                statusText = "Die Verarbeitung ist fehlgeschlagen."
            }
        }
    }

    func discardPendingAudio() {
        deletePendingAudio()
        state = .idle
        statusText = "Aufnahme verworfen."
    }

    func copyResult() {
        guard !resultText.isEmpty else { return }
        UIPasteboard.general.string = resultText
        statusText = "Text kopiert."
    }

    func finishSession() {
        resultText = ""
        rawText = ""
        showingOriginal = false
        state = .idle
        statusText = "Bereit für die nächste Aufnahme."
    }

    func consumeShortcutLaunch() {
        guard UserDefaults.standard.bool(forKey: Self.shortcutLaunchKey) else { return }
        UserDefaults.standard.set(false, forKey: Self.shortcutLaunchKey)
        guard isSetupComplete else { return }
        startRecording()
    }

    func appDidEnterBackground() {
        if state == .recording {
            finishRecording(interrupted: true)
        }
    }

    private func deletePendingAudio() {
        recorder.delete(pendingAudioURL)
        pendingAudioURL = nil
    }

    private func errorMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}

private extension ProcessingState {
    var processingText: String? {
        if case .processing(let text) = self { return text }
        return nil
    }
}
