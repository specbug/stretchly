import XCTest
@testable import StretchlyCore

final class BreakRulesTests: XCTestCase {
  let start = Date(timeIntervalSince1970: 1_700_000_000)

  func plannedBreak(postpones: Int = 0) -> PlannedBreak {
    PlannedBreak(kind: .mini, start: start, scheduledAt: start, sequence: 0, postpones: postpones)
  }

  func testPostponeOnlyInFirstPartOfBreak() {
    let settings = Settings()
    let early = BreakRules.moment(of: plannedBreak(), at: start.addingTimeInterval(5), settings: settings)
    XCTAssertTrue(early.canPostpone)
    XCTAssertFalse(early.canSkip)
    let late = BreakRules.moment(of: plannedBreak(), at: start.addingTimeInterval(7), settings: settings)
    XCTAssertFalse(late.canPostpone)
    XCTAssertTrue(late.canSkip)
  }

  func testPostponeLimitAllowsSkipRightAway() {
    let moment = BreakRules.moment(of: plannedBreak(postpones: 1), at: start, settings: Settings())
    XCTAssertFalse(moment.canPostpone)
    XCTAssertTrue(moment.canSkip)
  }

  func testStrictModeNeverSkips() {
    var settings = Settings()
    settings.microbreakStrictMode = true
    settings.microbreakPostpone = false
    let moment = BreakRules.moment(of: plannedBreak(), at: start.addingTimeInterval(10), settings: settings)
    XCTAssertFalse(moment.canSkip)
    XCTAssertFalse(moment.canPostpone)
  }

  func testStrictModeStillPostponesEarly() {
    var settings = Settings()
    settings.microbreakStrictMode = true
    let moment = BreakRules.moment(of: plannedBreak(), at: start, settings: settings)
    XCTAssertTrue(moment.canPostpone)
  }

  func testFinishedBreakOffersNothing() {
    let moment = BreakRules.moment(of: plannedBreak(), at: start.addingTimeInterval(30), settings: Settings())
    XCTAssertTrue(moment.isOver)
    XCTAssertFalse(moment.canSkip)
    XCTAssertFalse(moment.canPostpone)
  }

  func testMorningLaterToday() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let night = calendar.date(from: DateComponents(year: 2026, month: 10, day: 10, hour: 2))!
    let morning = calendar.date(from: DateComponents(year: 2026, month: 10, day: 10, hour: 6))!
    XCTAssertEqual(Morning.next(after: night, hour: 6, calendar: calendar), morning)
  }

  func testMorningTomorrow() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let evening = calendar.date(from: DateComponents(year: 2026, month: 10, day: 10, hour: 18))!
    let morning = calendar.date(from: DateComponents(year: 2026, month: 10, day: 11, hour: 6))!
    XCTAssertEqual(Morning.next(after: evening, hour: 6, calendar: calendar), morning)
  }

  func testSettingsDecodeDesktopKeysAndFillMissing() throws {
    let json = #"{"break": false, "microbreakInterval": 1200000, "unknownKey": 1}"#
    let settings = try JSONDecoder().decode(Settings.self, from: Data(json.utf8))
    XCTAssertFalse(settings.longBreak)
    XCTAssertEqual(settings.interval, 1200)
    XCTAssertEqual(settings.mainColor, "#478484")
  }
}
