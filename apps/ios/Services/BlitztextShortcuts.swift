import AppIntents

struct StartBlitztextIntent: AppIntent {
    static let title: LocalizedStringResource = "Blitztext-Aufnahme starten"
    static let description = IntentDescription("Öffnet Blitztext und startet eine Aufnahme mit dem zuletzt verwendeten Workflow.")
    static let supportedModes: IntentModes = .foreground

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppModel.shared.startRecording()
        }
        return .result()
    }
}

struct BlitztextShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartBlitztextIntent(),
            phrases: ["Starte eine Aufnahme mit \(.applicationName)", "\(.applicationName)-Aufnahme starten"],
            shortTitle: "Aufnahme starten",
            systemImageName: "mic.fill"
        )
    }
}
