import XCTest
@testable import StretchlyCore

final class TranslatorTests: XCTestCase {
  let english = Data("""
  {
    "break": { "postpone": "Postpone this break" },
    "utils": {
      "remaining": "{{count}} remaining",
      "seconds_one": "{{count}} second",
      "seconds_other": "{{count}} seconds",
      "minutes_one": "{{count}} minute",
      "minutes_other": "{{count}} minutes",
      "hours_one": "{{count}} hour",
      "hours_other": "{{count}} hours"
    },
    "miniBreakIdeas": {
      "aab": { "text": "Second" },
      "aaa": { "text": "First" }
    }
  }
  """.utf8)

  let czech = Data("""
  {
    "utils": {
      "minutes_one": "{{count}} minuta",
      "minutes_few": "{{count}} minuty",
      "minutes_many": "{{count}} minuty",
      "minutes_other": "{{count}} minut"
    }
  }
  """.utf8)

  func testFallsBackToEnglish() throws {
    let translator = try Translator(language: "cs", primaryJSON: czech, fallbackJSON: english)
    XCTAssertEqual(translator.t("break.postpone"), "Postpone this break")
    XCTAssertEqual(translator.t("missing.key"), "missing.key")
  }

  func testPluralCategories() throws {
    let translator = try Translator(language: "cs", primaryJSON: czech, fallbackJSON: english)
    XCTAssertEqual(translator.t("utils.minutes", count: 1), "1 minuta")
    XCTAssertEqual(translator.t("utils.minutes", count: 3), "3 minuty")
    XCTAssertEqual(translator.t("utils.minutes", count: 5), "5 minut")
    XCTAssertEqual(translator.t("utils.minutes", count: 1.5), "1.5 minuty")
  }

  func testInterpolation() throws {
    let translator = try Translator(language: "en", primaryJSON: nil, fallbackJSON: english)
    XCTAssertEqual(translator.t("utils.remaining", ["count": "5 minutes"]), "5 minutes remaining")
  }

  func testDurationRoundsLikeHumanizeDuration() throws {
    let translator = try Translator(language: "en", primaryJSON: nil, fallbackJSON: english)
    XCTAssertEqual(translator.duration(18.4, units: [.hours, .minutes, .seconds]), "18 seconds")
    XCTAssertEqual(translator.duration(90, units: [.hours, .minutes, .seconds]), "1 minute 30 seconds")
    XCTAssertEqual(translator.duration(3599.6, units: [.hours, .minutes, .seconds]), "1 hour")
    XCTAssertEqual(translator.duration(20, units: [.hours, .minutes]), "0 minutes")
    XCTAssertEqual(translator.duration(7 * 60 + 40, units: [.hours, .minutes]), "8 minutes")
  }

  func testUnitValueMatchesPreferencesOutput() throws {
    let translator = try Translator(language: "en", primaryJSON: nil, fallbackJSON: english)
    XCTAssertEqual(translator.unitValue(seconds: 20), "20 seconds")
    XCTAssertEqual(translator.unitValue(seconds: 60), "1 minute")
    XCTAssertEqual(translator.unitValue(seconds: 90), "1.5 minutes")
  }

  func testIdeaKeysAreSorted() throws {
    let translator = try Translator(language: "en", primaryJSON: nil, fallbackJSON: english)
    XCTAssertEqual(translator.keys(under: "miniBreakIdeas"), ["aaa", "aab"])
  }

  func testRussianPlurals() {
    XCTAssertEqual(PluralRules.category(for: "ru", count: 1), .one)
    XCTAssertEqual(PluralRules.category(for: "ru", count: 3), .few)
    XCTAssertEqual(PluralRules.category(for: "ru", count: 11), .many)
    XCTAssertEqual(PluralRules.category(for: "ru", count: 21), .one)
  }

  func testOtherPlurals() {
    XCTAssertEqual(PluralRules.category(for: "fr", count: 0), .one)
    XCTAssertEqual(PluralRules.category(for: "en", count: 0), .other)
    XCTAssertEqual(PluralRules.category(for: "pl", count: 22), .few)
    XCTAssertEqual(PluralRules.category(for: "pl", count: 25), .many)
    XCTAssertEqual(PluralRules.category(for: "sl", count: 102), .two)
    XCTAssertEqual(PluralRules.category(for: "ja", count: 1), .other)
    XCTAssertEqual(PluralRules.category(for: "lv", count: 10), .zero)
    XCTAssertEqual(PluralRules.category(for: "he", count: 2), .two)
  }

  func testIdeaDeckShowsEveryIdeaBeforeRepeating() {
    let count = 7
    let firstRound = (0..<count).map { IdeaDeck.index(for: $0, count: count, seed: 42) }
    XCTAssertEqual(Set(firstRound), Set(0..<count))
    XCTAssertEqual(IdeaDeck.index(for: 3, count: count, seed: 42), IdeaDeck.index(for: 3, count: count, seed: 42))
  }

  func testThemeMatchingIsCaseInsensitive() {
    XCTAssertEqual(Theme.matching("#1d1f21").nameKey, "preferences.theme.graphiteCrystal")
    XCTAssertEqual(Theme.matching("#123456").id, "#478484")
    XCTAssertTrue(Theme.matching("#FFFFFF").usesDarkText)
  }
}
