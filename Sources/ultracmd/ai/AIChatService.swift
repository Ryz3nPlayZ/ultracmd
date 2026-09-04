import Foundation

/// Streaming multi-model chat orchestrator. Reads SSE/NDJSON via
/// URLSession.AsyncBytes and forwards deltas as they arrive.
@MainActor
final class AIChatService: ObservableObject {
    @Published var isStreaming = false

    private var task: Task<Void, Never>?
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    var activeProvider: AIProvider { AIProvider(rawValue: SettingsStore.shared.aiProvider) ?? .openai }

    var activeModel: String {
        let s = SettingsStore.shared
        return s.aiModel.isEmpty ? activeProvider.defaultModel : s.aiModel
    }

    var apiKey: String? {
        Keychain.get(activeProvider.rawValue)
    }

    func cancel() {
        task?.cancel()
        task = nil
        isStreaming = false
    }

    /// Streamed completion. onDelta may fire many times; onFinish fires once
    /// with the full text (or the error).
    func stream(
        messages: [ChatMessage],
        provider: AIProvider? = nil,
        model: String? = nil,
        onDelta: @escaping @MainActor (String) -> Void,
        onFinish: @escaping @MainActor (Result<String, AIError>) -> Void
    ) {
        cancel()
        let p = provider ?? activeProvider
        let m = model ?? activeModel
        let settings = SettingsStore.shared
        let baseURL = p == .ollama ? settings.ollamaEndpoint : settings.customEndpoint

        guard let spec = try? AIWire.makeRequest(
            provider: p, model: m, messages: messages,
            baseURL: baseURL, apiKey: apiKey, streaming: true
        ) else {
            if p.needsAPIKey && (apiKey ?? "").isEmpty {
                onFinish(.failure(.missingAPIKey(p)))
            } else {
                onFinish(.failure(.emptyResponse))
            }
            return
        }

        isStreaming = true
        var urlRequest = URLRequest(url: URL(string: spec.url)!)
        urlRequest.httpMethod = spec.method
        urlRequest.httpBody = spec.body
        urlRequest.timeoutInterval = 120
        for (k, v) in spec.headers { urlRequest.setValue(v, forHTTPHeaderField: k) }

        task = Task { [weak self] in
            guard let self else { return }
            do {
                let (bytes, response) = try await session.bytes(for: urlRequest)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    var body = ""
                    for try await line in bytes.lines {
                        body += line
                        if body.count > 4000 { break }
                    }
                    let message = AIWire.parseErrorBody(Data(body.utf8))
                    self.finish(.failure(.http(http.statusCode, message)), onFinish)
                    return
                }

                var full = ""
                var buffer = ""
                for try await raw in bytes.lines {
                    if Task.isCancelled { break }
                    let line = raw.trimmingCharacters(in: .whitespaces)
                    buffer += line
                    guard let delta = AIWire.parseStreamLine(provider: p, line: line) else {
                        buffer = ""
                        continue
                    }
                    buffer = ""
                    full += delta
                    onDelta(delta)
                }
                _ = buffer
                if full.isEmpty {
                    self.finish(.failure(.emptyResponse), onFinish)
                } else {
                    self.finish(.success(full), onFinish)
                }
            } catch is CancellationError {
                // cancelled by user; finish silently
            } catch {
                self.finish(.failure(.network(error)), onFinish)
            }
        }
    }

    /// Non-streamed one-shot completion (used by selection rewriting).
    func complete(
        _ prompt: String,
        system: String? = nil,
        provider: AIProvider? = nil,
        model: String? = nil
    ) async throws -> String {
        let p = provider ?? activeProvider
        let m = model ?? activeModel
        let settings = SettingsStore.shared
        let baseURL = p == .ollama ? settings.ollamaEndpoint : settings.customEndpoint
        let systemPrompt = system ?? settings.aiSystemPrompt
        var messages: [ChatMessage] = []
        if !systemPrompt.isEmpty { messages.append(ChatMessage(role: .system, content: systemPrompt)) }
        messages.append(ChatMessage(role: .user, content: prompt))

        let spec = try AIWire.makeRequest(
            provider: p, model: m, messages: messages,
            baseURL: baseURL, apiKey: apiKey, streaming: false
        )
        var urlRequest = URLRequest(url: URL(string: spec.url)!)
        urlRequest.httpMethod = spec.method
        urlRequest.httpBody = spec.body
        urlRequest.timeoutInterval = 60
        for (k, v) in spec.headers { urlRequest.setValue(v, forHTTPHeaderField: k) }

        let (data, response) = try await session.data(for: urlRequest)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw AIError.http(http.statusCode, AIWire.parseErrorBody(data))
        }
        guard let text = AIWire.parseCompleteResponse(provider: p, body: data), !text.isEmpty else {
            throw AIError.emptyResponse
        }
        return text
    }

    private func finish(
        _ result: Result<String, AIError>,
        _ onFinish: @escaping @MainActor (Result<String, AIError>) -> Void
    ) {
        isStreaming = false
        task = nil
        onFinish(result)
    }
}
