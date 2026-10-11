import XCTest
@testable import StretchlyCore

final class LocalesTests: XCTestCase {
  let localesDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("../../../../app/locales")
    .standardized

  func testEveryDesktopLocaleResolvesKeysUsedOnIPad() throws {
    let english = try Data(contentsOf: localesDirectory.appendingPathComponent("en.json"))
    let files = try FileManager.default.contentsOfDirectory(atPath: localesDirectory.path).filter { $0.hasSuffix(".json") }
    XCTAssertGreaterThan(files.count, 40)

    for file in files {
      let language = String(file.dropLast(5))
      let data = try Data(contentsOf: localesDirectory.appendingPathComponent(file))
      let translator = try Translator(language: language, primaryJSON: data, fallbackJSON: english)
      for key in ["break.postpone", "break.skip", "statusMessages.nextMiniBreak", "main.resetBreaks", "ios.done"] {
        XCTAssertNotEqual(translator.t(key), key, "\(language): \(key)")
      }
      for count in [0.0, 1, 2, 3, 5, 11, 21, 1.5] {
        for key in ["utils.seconds", "utils.minutes", "utils.hours", "statusMessages.afterMiniBreak"] {
          let text = translator.t(key, count: count)
          XCTAssertFalse(text.contains("utils.") || text.contains("statusMessages."), "\(language): \(key) \(count)")
          XCTAssertFalse(text.contains("{{"), "\(language): \(key) \(count) -> \(text)")
        }
      }
      let plannedBreak = PlannedBreak(kind: .long, start: Date(), scheduledAt: Date(), sequence: 3, postpones: 0)
      XCTAssertFalse(IdeaDeck.idea(for: plannedBreak, seed: 7, translator: translator).text.isEmpty, language)
    }
  }
}
