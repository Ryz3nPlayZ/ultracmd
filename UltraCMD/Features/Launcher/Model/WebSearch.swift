import Foundation

/// The engines the "Search the Web" fallback can hand a query to.
enum WebSearchEngine: String, CaseIterable, Identifiable, Sendable {
    case google
    case duckduckgo
    case bing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .google: return "Google"
        case .duckduckgo: return "DuckDuckGo"
        case .bing: return "Bing"
        }
    }

    private var searchTemplate: String {
        switch self {
        case .google: return "https://www.google.com/search"
        case .duckduckgo: return "https://duckduckgo.com/"
        case .bing: return "https://www.bing.com/search"
        }
    }

    func url(for query: String) -> URL? {
        var components = URLComponents(string: searchTemplate)
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}
