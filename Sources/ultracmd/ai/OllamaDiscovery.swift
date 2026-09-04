import Foundation

/// Dynamic local Ollama model discovery: polls `GET {endpoint}/api/tags` and
/// publishes the installed model list (e.g. llama3.2:latest, deepseek-r1:8b)
/// so the settings UI and model pickers never rely on hardcoded names.
@MainActor
final class OllamaDiscovery: ObservableObject {
    @Published private(set) var models: [String] = []
    @Published private(set) var lastError: String?
    @Published private(set) var checking = false

    struct TagsResponse: Decodable {
        struct Tag: Decodable {
            let name: String?
            let model: String?
        }
        let models: [Tag]?
    }

    /// Pure parser (unit-tested) so the payload shape is pinned down.
    nonisolated static func parseTags(_ data: Data) throws -> [String] {
        let decoded = try JSONDecoder().decode(TagsResponse.self, from: data)
        return (decoded.models ?? []).compactMap { $0.name ?? $0.model }
    }

    func refresh(endpoint: String? = nil) async {
        let base = (endpoint ?? SettingsStore.shared.ollamaEndpoint)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: base + "/api/tags") else {
            lastError = "Invalid endpoint URL"
            models = []
            return
        }
        checking = true
        defer { checking = false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            models = try Self.parseTags(data)
            lastError = models.isEmpty ? "No models installed" : nil
        } catch {
            models = []
            lastError = error.localizedDescription
        }
    }
}
