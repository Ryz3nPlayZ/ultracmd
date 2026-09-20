import Foundation
import Observation

/// The two picks the screen keeps between visits: the source (nil is Auto) and the target.
@MainActor
@Observable
final class TranslateSettings {
    private let defaults: UserDefaults

    var sourceOverride: Locale.Language? {
        didSet {
            if let sourceOverride {
                defaults.set(
                    sourceOverride.minimalIdentifier,
                    forKey: AppSettingsKey.translateSourceLanguage.rawValue)
            } else {
                defaults.removeObject(forKey: AppSettingsKey.translateSourceLanguage.rawValue)
            }
        }
    }

    var target: Locale.Language {
        didSet {
            defaults.set(
                target.minimalIdentifier, forKey: AppSettingsKey.translateTargetLanguage.rawValue)
        }
    }

    /// No stored target means "this Mac's own language", snapped to something the framework has
    /// once its list lands.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sourceOverride = defaults
            .string(forKey: AppSettingsKey.translateSourceLanguage.rawValue)
            .map { Locale.Language(identifier: $0) }
        target = defaults
            .string(forKey: AppSettingsKey.translateTargetLanguage.rawValue)
            .map { Locale.Language(identifier: $0) }
            ?? Locale.Language(identifier: Locale.preferredLanguages.first ?? "en")
    }
}
