import AppIntents

struct StartBlitztextIntent: AppIntent {
    static let title: LocalizedStringResource = "Blitztext-Aufnahme starten"
    static let description = IntentDescription("Öffnet Blitztext und startet eine Aufnahme mit dem zuletzt verwendeten Workflow.")
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: AppModel.shortcutLaunchKey)
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
