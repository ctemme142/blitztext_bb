import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var message: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("API-Zugang") {
                    SecureField("Neuen API-Schlüssel eingeben", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        isSaving = true
                        message = nil
                        Task {
                            let result = await model.changeAPIKey(apiKey)
                            await MainActor.run {
                                message = result ?? "API-Schlüssel gespeichert."
                                isSaving = false
                                if result == nil { apiKey = "" }
                            }
                        }
                    } label: {
                        HStack {
                            Text(isSaving ? "Prüfe Verbindung ..." : "Schlüssel speichern")
                            if isSaving { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)

                    Button("API-Schlüssel löschen", role: .destructive) {
                        model.deleteAPIKey()
                    }
                }

                Section("Verarbeitung") {
                    LabeledContent("Transkription", value: "Online über OpenAI")
                    LabeledContent("Sprache", value: "Deutsch")
                    LabeledContent("Verlauf", value: "Nicht gespeichert")
                }

                Section("Datenschutz") {
                    Text("Audioaufnahmen werden zur Transkription an OpenAI gesendet. Temporäre Audiodateien werden nach erfolgreicher Verarbeitung gelöscht.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let message {
                    Section {
                        Text(message)
                            .foregroundStyle(message.contains("gespeichert") ? .green : .red)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
