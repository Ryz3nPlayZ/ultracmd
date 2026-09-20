import Foundation

/// One translation request, resolved: the engine is Apple's on-device translator, so nothing a
/// user types ever leaves the Mac for this feature.
enum TranslateEngine {
    enum Failure: Error, Equatable {
        case undetectable
        case needsDownload(language: String)
        case unsupportedPair
        case failed

        var message: String {
            switch self {
            case .undetectable:
                return "The language of this text could not be identified."
            case .needsDownload(let language):
                return
                    "\(language) needs to be downloaded first — System Settings › General › "
                    + "Language & Region › Translation Languages."
            case .unsupportedPair:
                return "This language pair is not supported by the on-device translator."
            case .failed:
                return "The text could not be translated."
            }
        }
    }

    static func translate(
        _ text: String, source: Locale.Language?, target: Locale.Language
    ) async -> Result<String, Failure> {
        let resolved = source ?? TextTranslator.sourceLanguage(of: text)
        guard let resolved else { return .failure(.undetectable) }
        do {
            return .success(try await TextTranslator.translate(text, from: resolved, to: target))
        } catch let failure as TextTranslator.Failure {
            switch failure {
            case .undetectableSource: return .failure(.undetectable)
            case .notInstalled(let language): return .failure(.needsDownload(language: language))
            case .unsupported: return .failure(.unsupportedPair)
            case .failed: return .failure(.failed)
            }
        } catch {
            return .failure(.failed)
        }
    }
}
