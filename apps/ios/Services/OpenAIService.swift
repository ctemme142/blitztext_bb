import Foundation

enum OpenAIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case network(String)
    case api(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Der OpenAI-API-Schlüssel fehlt."
        case .invalidResponse:
            return "Die Antwort von OpenAI war ungültig."
        case .network(let message):
            return "Netzwerkfehler: \(message)"
        case .api(let message):
            return "OpenAI-Fehler: \(message)"
        case .emptyResponse:
            return "OpenAI hat keinen Text zurückgegeben."
        }
    }
}

enum OpenAIService {
    private static let transcriptionURL = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private static let chatURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private static let modelsURL = URL(string: "https://api.openai.com/v1/models")!

    static func validateAPIKey(_ value: String) async throws {
        let key = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw OpenAIServiceError.missingAPIKey }
        var request = URLRequest(url: modelsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
        } catch let error as OpenAIServiceError {
            throw error
        } catch {
            throw OpenAIServiceError.network(error.localizedDescription)
        }
    }

    static func transcribe(audioURL: URL, language: String = "de") async throws -> String {
        guard let apiKey = KeychainService.loadAPIKey() else {
            throw OpenAIServiceError.missingAPIKey
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: transcriptionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("text/plain, application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60

        var body = Data()
        body.appendMultipart("file", filename: "audio.m4a", contentType: "audio/m4a", data: try Data(contentsOf: audioURL), boundary: boundary)
        body.appendMultipart("model", value: "whisper-1", boundary: boundary)
        body.appendMultipart("response_format", value: "text", boundary: boundary)
        body.appendMultipart("language", value: language, boundary: boundary)
        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            guard let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else {
                throw OpenAIServiceError.emptyResponse
            }
            return text
        } catch let error as OpenAIServiceError {
            throw error
        } catch {
            throw OpenAIServiceError.network(error.localizedDescription)
        }
    }

    static func rewrite(_ text: String, for workflow: WorkflowType) async throws -> String {
        let prompt: String
        let model: String
        switch workflow {
        case .transcription:
            return text
        case .textImprover:
            model = "gpt-4o-mini"
            prompt = "Du bist ein Lektor. Verbessere Rechtschreibung, Grammatik und Lesefluss. Behalte die Bedeutung bei. Gib NUR den verbesserten Text zurück, ohne Erklärungen."
        case .dampfAblassen:
            model = "gpt-4o"
            prompt = "Formuliere das emotionale Transkript in eine klare, respektvolle und bestimmte Nachricht um. Bewahre Fakten, Anliegen und Grenzen. Entferne Beleidigungen, Drohungen und unnötige Eskalation. Gib NUR die fertige Nachricht zurück."
        case .emojiText:
            model = "gpt-4o-mini"
            prompt = "Gib das Transkript möglichst originalgetreu zurück, korrigiere offensichtliche Sprachfehler und ergänze passende Emojis. Gib NUR den fertigen Text zurück."
        }

        guard let apiKey = KeychainService.loadAPIKey() else {
            throw OpenAIServiceError.missingAPIKey
        }

        let payload = ChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: prompt),
                .init(role: "user", content: text),
            ],
            temperature: workflow == .dampfAblassen ? 0.4 : 0.3
        )

        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(payload)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
            guard let content = decoded.choices?.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !content.isEmpty else {
                throw OpenAIServiceError.emptyResponse
            }
            return content
        } catch let error as OpenAIServiceError {
            throw error
        } catch {
            throw OpenAIServiceError.network(error.localizedDescription)
        }
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data)).flatMap { $0.error?.message }
            throw OpenAIServiceError.api(message ?? "Status \(httpResponse.statusCode)")
        }
    }
}

private struct ChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]?
}

private struct APIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String?
    }

    let error: APIError?
}

private extension Data {
    mutating func appendString(_ value: String) {
        append(Data(value.utf8))
    }

    mutating func appendMultipart(_ name: String, value: String, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        appendString("\(value)\r\n")
    }

    mutating func appendMultipart(_ name: String, filename: String, contentType: String, data: Data, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(contentType)\r\n\r\n")
        append(data)
        appendString("\r\n")
    }
}
