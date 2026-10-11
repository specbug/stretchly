import XCTest
@testable import StretchlyCore

final class PlannerTests: XCTestCase {
  let start = Date(timeIntervalSince1970: 1_700_000_000)
  let settings = Settings()

  func startedPlanner(_ settings: Settings? = nil) -> Planner {
    var planner = Planner(seed: 1)
    planner.reset(at: start, settings: settings ?? self.settings)
    return planner
  }

  func testFirstBreakIsMiniAfterInterval() {
    let planner = startedPlanner()
    XCTAssertEqual(planner.next?.kind, .mini)
    XCTAssertEqual(planner.next?.start, start.addingTimeInterval(600))
    XCTAssertEqual(planner.breakNumber, 1)
  }

  func testEveryThirdBreakIsLongByDefault() {
    let kinds = startedPlanner().upcoming(from: start, settings: settings, limit: 6).map(\.kind)
    XCTAssertEqual(kinds, [.mini, .mini, .long, .mini, .mini, .long])
  }

  func testNextIntervalCountsFromEndOfBreak() {
    let breaks = startedPlanner().upcoming(from: start, settings: settings, limit: 3)
    XCTAssertEqual(breaks[1].start, breaks[0].start.addingTimeInterval(20 + 600))
    XCTAssertEqual(breaks[2].start, breaks[1].start.addingTimeInterval(20 + 600))
  }

  func testOnlyLongBreaksUseMultipliedInterval() {
    var settings = Settings()
    settings.microbreak = false
    let planner = startedPlanner(settings)
    XCTAssertEqual(planner.next?.kind, .long)
    XCTAssertEqual(planner.next?.start, start.addingTimeInterval(600 * 3))
  }

  func testNoBreaksWhenBothDisabled() {
    var settings = Settings()
    settings.microbreak = false
    settings.longBreak = false
    XCTAssertEqual(startedPlanner(settings).phase(at: start, settings: settings), .idle)
  }

  func testPhaseFollowsTime() {
    let planner = startedPlanner()
    let breakStart = start.addingTimeInterval(600)
    guard case .waiting = planner.phase(at: start, settings: settings) else { return XCTFail() }
    guard case .onBreak(let current) = planner.phase(at: breakStart.addingTimeInterval(5), settings: settings) else { return XCTFail() }
    XCTAssertEqual(current.kind, .mini)
    guard case .waiting(let next) = planner.phase(at: breakStart.addingTimeInterval(21), settings: settings) else { return XCTFail() }
    XCTAssertEqual(next.start, breakStart.addingTimeInterval(620))
  }

  func testAdvanceMatchesProjection() {
    var planner = startedPlanner()
    let projected = planner.upcoming(from: start, settings: settings, limit: 10)
    let moment = projected[7].start.addingTimeInterval(1)
    planner.advance(to: moment, settings: settings)
    XCTAssertEqual(planner.next, projected[7])
  }

  func testLongAbsenceResetsSchedule() {
    var planner = startedPlanner()
    let later = start.addingTimeInterval(Planner.horizon * 2)
    planner.advance(to: later, settings: settings)
    XCTAssertEqual(planner.next?.start, later.addingTimeInterval(600))
    XCTAssertEqual(planner.breakNumber, 1)
  }

  func testPostponeKeepsKindAndIdea() {
    var planner = startedPlanner()
    let original = planner.next!
    let now = original.start.addingTimeInterval(2)
    planner.postpone(at: now, settings: settings)
    XCTAssertEqual(planner.next?.kind, .mini)
    XCTAssertEqual(planner.next?.sequence, original.sequence)
    XCTAssertEqual(planner.next?.postpones, 1)
    XCTAssertEqual(planner.next?.start, now.addingTimeInterval(120))
  }

  func testFinishPlansFromNow() {
    var planner = startedPlanner()
    let now = start.addingTimeInterval(605)
    planner.finish(at: now, settings: settings)
    XCTAssertEqual(planner.next?.start, now.addingTimeInterval(600))
    XCTAssertEqual(planner.breakNumber, 2)
  }

  func testSkipToLongStartsNowAndRestartsCycle() {
    var planner = startedPlanner()
    planner.skipToLong(at: start, settings: settings)
    XCTAssertEqual(planner.next?.kind, .long)
    XCTAssertEqual(planner.next?.start, start)
    planner.finish(at: start.addingTimeInterval(300), settings: settings)
    XCTAssertEqual(planner.next?.kind, .mini)
  }

  func testSkipToMiniAfterLongKeepsCycle() {
    var planner = startedPlanner()
    planner.skipToLong(at: start, settings: settings)
    planner.skipToMini(at: start, settings: settings)
    XCTAssertEqual(planner.breakNumber, 1)
    XCTAssertEqual(planner.next?.kind, .mini)
  }

  func testTimedPauseResumesAtEnd() {
    var planner = startedPlanner()
    let end = start.addingTimeInterval(3600)
    planner.pause(until: end)
    XCTAssertEqual(planner.phase(at: start, settings: settings), .paused(until: end))
    planner.advance(to: end.addingTimeInterval(1), settings: settings)
    XCTAssertEqual(planner.next?.start, end.addingTimeInterval(600))
    XCTAssertEqual(planner.breakNumber, 1)
  }

  func testIndefinitePauseHasNoNotices() {
    var planner = startedPlanner()
    planner.pause(until: nil)
    XCTAssertTrue(planner.notices(from: start, settings: settings).isEmpty)
  }

  func testTimedPauseNoticesStartWithResume() {
    var planner = startedPlanner()
    let end = start.addingTimeInterval(3600)
    planner.pause(until: end)
    let notices = planner.notices(from: start, settings: settings)
    XCTAssertEqual(notices.first?.content, .resume)
    XCTAssertEqual(notices.first?.date, end)
    XCTAssertEqual(notices.dropFirst().first?.date, end.addingTimeInterval(600))
  }

  func testNoticesStayWithinLimitAndHorizon() {
    let notices = startedPlanner().notices(from: start, settings: settings)
    XCTAssertLessThanOrEqual(notices.count, Planner.noticeLimit)
    XCTAssertTrue(notices.allSatisfy { $0.date <= start.addingTimeInterval(Planner.horizon) })
    XCTAssertEqual(Set(notices.map(\.id)).count, notices.count)
  }

  func testLongBreakAfterMinisCountsDown() {
    var planner = startedPlanner()
    XCTAssertEqual(planner.longBreakAfterMinis(settings: settings), 2)
    planner.finish(at: start.addingTimeInterval(620), settings: settings)
    XCTAssertEqual(planner.longBreakAfterMinis(settings: settings), 1)
    planner.finish(at: start.addingTimeInterval(1240), settings: settings)
    XCTAssertNil(planner.longBreakAfterMinis(settings: settings))
  }

  func testProgressTowardsNextBreak() {
    let planner = startedPlanner()
    XCTAssertEqual(planner.progress(at: start.addingTimeInterval(300)), 0.5, accuracy: 0.0001)
  }

  func testPlannerRoundTripsThroughJSON() throws {
    var planner = startedPlanner()
    planner.pause(until: start)
    let data = try JSONEncoder().encode(planner)
    XCTAssertEqual(try JSONDecoder().decode(Planner.self, from: data), planner)
  }
}
