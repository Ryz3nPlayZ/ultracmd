import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openai
    case anthropic
    case gemini
    case ollama
    case custom // any OpenAI-compatible endpoint (LM Studio, MLX serve, llama.cpp server…)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic (Claude)"
        case .gemini: return "Google Gemini"
        case .ollama: return "Ollama (local)"
        case .custom: return "Custom (OpenAI-compatible)"
        }
    }

    var defaultModel: String {
        switch self {
        case .openai: return "gpt-4o-mini"
        case .anthropic: return "claude-sonnet-4-5"
        case .gemini: return "gemini-2.0-flash"
        case .ollama: return "llama3.2"
        case .custom: return "local-model"
        }
    }

    var needsAPIKey: Bool {
        self == .openai || self == .anthropic || self == .gemini
    }

    var defaultBaseURL: String {
        switch self {
        case .openai: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
        case .ollama: return "http://127.0.0.1:11434"
        case .custom: return "http://127.0.0.1:8080/v1"
        }
    }
}

struct ChatMessage: Identifiable, Equatable {
    enum Role: String { case system, user, assistant }

    var id = UUID()
    var role: Role
    var content: String
}

// Wire-format payload structs (file scope so Codable synthesis works).

private struct OpenAIChatPayload: Codable {
    struct Msg: Codable { let role: String; let content: String }
    let model: String
    let messages: [Msg]
    let stream: Bool
}

private struct AnthropicPayload: Codable {
    struct Msg: Codable { let role: String; let content: String }
    let model: String
    let system: String?
    let messages: [Msg]
    let max_tokens: Int
    let stream: Bool
}

private struct GeminiPayload: Codable {
    struct Part: Codable { let text: String }
    struct Content: Codable { let role: String; let parts: [Part] }
    struct SystemInstruction: Codable { let parts: [Part] }
    let systemInstruction: SystemInstruction?
    let contents: [Content]
}

private struct OllamaPayload: Codable {
    struct Msg: Codable { let role: String; let content: String }
    let model: String
    let messages: [Msg]
    let stream: Bool
}

/// Pure request/response plumbing for every provider — unit-testable without
/// network access. Streaming parsing follows each provider's wire format:
/// OpenAI/Gemini use SSE `data:` lines; Anthropic uses SSE events; Ollama
/// streams newline-delimited JSON.
enum AIWire {

    struct RequestSpec: Equatable {
        var url: String
        var method: String = "POST"
        var headers: [String: String]
        var body: Data
    }

    static func makeRequest(
        provider: AIProvider,
        model: String,
        messages: [ChatMessage],
        baseURL: String? = nil,
        apiKey: String? = nil,
        streaming: Bool = true
    ) throws -> RequestSpec {
        let base = (baseURL?.isEmpty == false ? baseURL! : provider.defaultBaseURL)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch provider {
        case .openai, .custom:
            let payload = OpenAIChatPayload(
                model: model,
                messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) },
                stream: streaming
            )
            var headers = ["Content-Type": "application/json"]
            if let apiKey, !apiKey.isEmpty { headers["Authorization"] = "Bearer \(apiKey)" }
            return RequestSpec(
                url: "\(base)/chat/completions",
                headers: headers,
                body: try JSONEncoder().encode(payload)
            )

        case .anthropic:
            let system = messages.first { $0.role == .system }?.content
            let rest = messages.filter { $0.role != .system }
            let payload = AnthropicPayload(
                model: model,
                system: system,
                messages: rest.map { .init(role: $0.role.rawValue, content: $0.content) },
                max_tokens: 4096,
                stream: streaming
            )
            var headers = [
                "Content-Type": "application/json",
                "anthropic-version": "2023-06-01",
            ]
            if let apiKey, !apiKey.isEmpty { headers["x-api-key"] = apiKey }
            return RequestSpec(
                url: "\(base)/messages",
                headers: headers,
                body: try JSONEncoder().encode(payload)
            )

        case .gemini:
            let system = messages.first { $0.role == .system }?.content
            let rest = messages.filter { $0.role != .system }
            let payload = GeminiPayload(
                systemInstruction: system.map { .init(parts: [.init(text: $0)]) },
                contents: rest.map { msg in
                    GeminiPayload.Content(
                        role: msg.role == .assistant ? "model" : "user",
                        parts: [.init(text: msg.content)]
                    )
                }
            )
            guard let apiKey, !apiKey.isEmpty else {
                throw AIError.missingAPIKey(provider)
            }
            let verb = streaming ? ":streamGenerateContent?alt=sse&key=" : ":generateContent?key="
            return RequestSpec(
                url: "\(base)/models/\(model)\(verb)\(apiKey)",
                headers: ["Content-Type": "application/json"],
                body: try JSONEncoder().encode(payload)
            )

        case .ollama:
            let payload = OllamaPayload(
                model: model,
                messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) },
                stream: streaming
            )
            return RequestSpec(
                url: "\(base)/api/chat",
                headers: ["Content-Type": "application/json"],
                body: try JSONEncoder().encode(payload)
            )
        }
    }

    /// Extract the newest text delta from one streaming line (SSE data payload
    /// or a raw NDJSON object). Returns nil for non-content lines.
    static func parseStreamLine(provider: AIProvider, line: String) -> String? {
        guard !line.isEmpty else { return nil }
        let data = line.hasPrefix("data: ") ? String(line.dropFirst(6)) : line
        if data == "[DONE]" { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: Data(data.utf8)) as? [String: Any] else {
            return nil
        }
        switch provider {
        case .openai, .custom:
            guard let choices = obj["choices"] as? [[String: Any]], let first = choices.first else { return nil }
            let delta = first["delta"] as? [String: Any]
            if let text = delta?["content"] as? String { return text }
            if let text = first["text"] as? String { return text } // legacy completions
            return nil
        case .anthropic:
            guard let type = obj["type"] as? String else { return nil }
            if type == "content_block_delta",
               let delta = obj["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                return text
            }
            return nil
        case .gemini:
            guard let candidates = obj["candidates"] as? [[String: Any]], let first = candidates.first,
                  let content = first["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else { return nil }
            return text
        case .ollama:
            guard let message = obj["message"] as? [String: Any],
                  let text = message["content"] as? String else { return nil }
            return text
        }
    }

    /// Extract full text from a non-streaming response.
    static func parseCompleteResponse(provider: AIProvider, body: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return nil }
        switch provider {
        case .openai, .custom:
            let choices = obj["choices"] as? [[String: Any]]
            let message = choices?.first?["message"] as? [String: Any]
            return message?["content"] as? String
        case .anthropic:
            let content = obj["content"] as? [[String: Any]]
            return content?.compactMap { $0["text"] as? String }.joined()
        case .gemini:
            let candidates = obj["candidates"] as? [[String: Any]]
            let content = candidates?.first?["content"] as? [String: Any]
            let parts = content?["parts"] as? [[String: Any]]
            return parts?.compactMap { $0["text"] as? String }.joined()
        case .ollama:
            let message = obj["message"] as? [String: Any]
            return message?["content"] as? String
        }
    }

    /// Extract an error message from an HTTP error body.
    static func parseErrorBody(_ body: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return nil }
        if let error = obj["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }
        if let error = obj["error"] as? String { return error }
        if let message = obj["message"] as? String { return message }
        return nil
    }
}

enum AIError: LocalizedError {
    case missingAPIKey(AIProvider)
    case http(Int, String?)
    case emptyResponse
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let p):
            return "No API key configured for \(p.displayName). Add it in Settings → AI."
        case .http(let code, let message):
            return message.map { "HTTP \(code): \($0)" } ?? "HTTP error \(code)"
        case .emptyResponse:
            return "The model returned an empty response."
        case .network(let err):
            return err.localizedDescription
        }
    }
}
