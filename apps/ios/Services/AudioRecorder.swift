import AVFoundation
import Foundation

@MainActor
final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var audioLevel: Float = 0
    private(set) var diagnostic = "Noch keine Aufnahme gestartet."

    var onTimeLimitReached: (() -> Void)?
    var onInterruption: (() -> Void)?

    private let maxDuration: TimeInterval = 5 * 60
    private var recorder: AVAudioRecorder?
    private var timerTask: Task<Void, Never>?
    private var currentFileURL: URL?
    private var recordingStartDate: Date?
    private var interruptionObserver: NSObjectProtocol?

    override init() {
        super.init()
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue),
                  type == .began else { return }
            Task { @MainActor [weak self] in
                self?.handleInterruption()
            }
        }
    }

    func start() async throws {
        let permission = await requestPermission()
        diagnostic = "Mikrofonberechtigung: \(permission ? "erlaubt" : "verweigert")"
        guard permission else {
            throw AudioRecorderError.microphonePermissionDenied
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        let inputs = session.currentRoute.inputs.map(\.portName).joined(separator: ", ")
        diagnostic = "Audioeingang: \(inputs.isEmpty ? "kein Eingang gemeldet" : inputs)"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("blitztext-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let newRecorder = try AVAudioRecorder(url: url, settings: settings)
        newRecorder.delegate = self
        newRecorder.isMeteringEnabled = true
        recorder = newRecorder
        currentFileURL = url
        guard newRecorder.record() else {
            recorder = nil
            currentFileURL = nil
            try? FileManager.default.removeItem(at: url)
            throw AudioRecorderError.couldNotStart
        }

        isRecording = true
        recordingStartDate = Date()
        diagnostic += "; Rekorder gestartet; Datei: (url.lastPathComponent)"
        elapsed = 0
        audioLevel = 0
        startTimer()
    }

    func stop() -> URL? {
        stopTimer()
        if let recordingStartDate {
            elapsed = Date().timeIntervalSince(recordingStartDate)
        }
        recorder?.stop()
        isRecording = false
        let url = currentFileURL ?? latestRecordingURL()
        if let url {
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue ?? 0
            diagnostic += "; Datei nach Stop: \(size) Bytes"
        } else {
            diagnostic += "; keine Audiodatei nach Stop gefunden"
        }
        currentFileURL = nil
        recordingStartDate = nil
        recorder = nil
        audioLevel = 0
        deactivateSession()
        return url
    }

    private func latestRecordingURL() -> URL? {
        let directory = FileManager.default.temporaryDirectory
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return files
            .filter { $0.lastPathComponent.hasPrefix("blitztext-") && $0.pathExtension == "m4a" }
            .sorted { lhs, rhs in
                let left = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let right = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return left > right
            }
            .first
    }

    func cancel() {
        stopTimer()
        recorder?.stop()
        isRecording = false
        if let currentFileURL {
            try? FileManager.default.removeItem(at: currentFileURL)
        }
        currentFileURL = nil
        recordingStartDate = nil
        recorder = nil
        elapsed = 0
        audioLevel = 0
        deactivateSession()
    }

    func delete(_ url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func requestPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let recorder = self.recorder else { return }
                if let recordingStartDate = self.recordingStartDate {
                    self.elapsed = Date().timeIntervalSince(recordingStartDate)
                }
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)
                self.audioLevel = max(0, min(1, (power + 50) / 50))
                if self.elapsed >= self.maxDuration {
                    self.onTimeLimitReached?()
                    return
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func handleInterruption() {
        guard isRecording else { return }
        onInterruption?()
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Task { @MainActor [weak self] in
                self?.onInterruption?()
            }
        }
    }
}

enum AudioRecorderError: LocalizedError {
    case microphonePermissionDenied
    case couldNotStart

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Der Mikrofonzugriff ist nicht erlaubt. Bitte aktivieren Sie ihn in den iPhone-Einstellungen."
        case .couldNotStart:
            return "Die Aufnahme konnte nicht gestartet werden."
        }
    }
}
