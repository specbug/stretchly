import Foundation
import Observation
import StretchlyCore
import SwiftUI

struct Language: Decodable, Identifiable, Hashable {
  let code: String
  let name: String

  var id: String { code }
}

@MainActor
@Observable
final class Localizer {
  private(set) var translator: Translator
  let languages: [Language]

  init(language: String) {
    languages = Localizer.loadLanguages()
    translator = Localizer.translator(for: language)
  }

  var layoutDirection: LayoutDirection {
    translator.isRightToLeft ? .rightToLeft : .leftToRight
  }

  func use(_ language: String) {
    guard language != translator.language else { return }
    translator = Localizer.translator(for: language)
  }

  func t(_ key: String, _ values: [String: String] = [:]) -> String {
    translator.t(key, values)
  }

  func t(_ key: String, count: Double) -> String {
    translator.t(key, count: count)
  }

  func remaining(_ seconds: TimeInterval) -> String {
    t("utils.remaining", ["count": translator.duration(seconds, units: [.hours, .minutes, .seconds])])
  }

  func inAbout(_ seconds: TimeInterval) -> String {
    t("utils.inAbout", ["count": translator.duration(seconds, units: [.hours, .minutes])])
  }

  func unitValue(seconds: TimeInterval) -> String {
    translator.unitValue(seconds: seconds)
  }

  static func preferredLanguage() -> String {
    let available = Set(loadLanguages().map(\.code))
    let aliases = ["zh-Hans": "zh-CN", "zh-Hant": "zh-TW", "nb": "nb-NO", "no": "nb-NO", "ne": "np", "pa": "pu", "ar": "arz"]
    for identifier in Locale.preferredLanguages {
      let parts = identifier.split(separator: "-").map(String.init)
      let candidates = [
        identifier,
        parts.prefix(2).joined(separator: "-"),
        aliases[parts.prefix(2).joined(separator: "-")],
        aliases[parts.first ?? ""],
        parts.first
      ]
      if let match = candidates.compactMap({ $0 }).first(where: available.contains) {
        return match
      }
    }
    return Translator.fallbackLanguage
  }

  private static func translator(for language: String) -> Translator {
    let fallback = localeData(Translator.fallbackLanguage) ?? Data("{}".utf8)
    if let translator = try? Translator(language: language, primaryJSON: localeData(language), fallbackJSON: fallback) {
      return translator
    }
    return Translator(language: Translator.fallbackLanguage, primary: .group([:]), fallback: .group([:]))
  }

  private static func localeData(_ name: String) -> Data? {
    Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Locales")
      .flatMap { try? Data(contentsOf: $0) }
  }

  private static func loadLanguages() -> [Language] {
    localeData("languages").flatMap { try? JSONDecoder().decode([Language].self, from: $0) } ?? []
  }
}
