import Foundation

enum WeatherLocalization {
    static func string(_ key: String, locale: Locale? = nil, bundle: Bundle = .main) -> String {
        if let locale {
            let identifiers = [locale.identifier, locale.language.languageCode?.identifier].compactMap { $0 }
            for identifier in identifiers {
                guard let path = bundle.path(forResource: identifier, ofType: "lproj"),
                      let localizedBundle = Bundle(path: path) else { continue }
                return localizedBundle.localizedString(forKey: key, value: key, table: nil)
            }
        }
        return String(localized: String.LocalizationValue(key), bundle: bundle)
    }
}
