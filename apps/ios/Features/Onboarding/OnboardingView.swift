import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: AppModel
    @State private var apiKey = ""
    @State private var isTesting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Blitztext einrichten")
                            .font(.largeTitle.bold())
                        Text("Sprache aufnehmen, verarbeiten und direkt kopieren.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Mikrofonzugriff", systemImage: "mic.fill")
                        Text("Blitztext benötigt das Mikrofon für die Aufnahme. Der Zugriff wird beim ersten Aufnahmestart abgefragt.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("OpenAI-API-Schlüssel", systemImage: "key.fill")
                        SecureField("API-Schlüssel einfügen", text: $apiKey)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        Text("Die Audioaufnahme wird zur Online-Transkription an OpenAI gesendet. Der Schlüssel wird nur im iOS-Keychain gespeichert.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }

                    Button {
                        isTesting = true
                        errorMessage = nil
                        Task {
                            let result = await model.completeSetup(with: apiKey)
                            await MainActor.run {
                                errorMessage = result
                                isTesting = false
                            }
                        }
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView().tint(.white)
                            }
                            Text(isTesting ? "Verbindung wird geprüft ..." : "Einrichtung abschließen")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)
                }
                .padding(24)
            }
            .navigationTitle("Willkommen")
        }
    }
}
