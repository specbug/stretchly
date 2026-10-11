import Foundation

public struct PlannedBreak: Codable, Hashable, Identifiable, Sendable {
  public let kind: BreakKind
  public let start: Date
  public let scheduledAt: Date
  public let sequence: Int
  public let postpones: Int

  public var id: String { "\(kind.rawValue)-\(sequence)" }

  public func end(_ settings: Settings) -> Date {
    start.addingTimeInterval(settings.duration(kind))
  }
}

public enum PauseState: Codable, Equatable, Sendable {
  case running
  case until(Date)
  case indefinitely
}

public enum Phase: Equatable, Sendable {
  case idle
  case paused(until: Date?)
  case waiting(PlannedBreak)
  case onBreak(PlannedBreak)
}

public struct Notice: Equatable, Sendable {
  public enum Content: Equatable, Sendable {
    case breakStart(PlannedBreak)
    case resume
  }

  public let id: String
  public let date: Date
  public let content: Content
}

public struct Planner: Codable, Equatable, Sendable {
  public static let horizon: TimeInterval = 12 * 60 * 60
  public static let noticeLimit = 60

  public private(set) var breakNumber = 0
  public private(set) var next: PlannedBreak?
  public private(set) var pauseState = PauseState.running
  public private(set) var miniSequence = 0
  public private(set) var longSequence = 0
  public let seed: UInt64

  public init(seed: UInt64 = UInt64.random(in: .min ... .max)) {
    self.seed = seed
  }

  public func phase(at now: Date, settings: Settings) -> Phase {
    var planner = self
    planner.advance(to: now, settings: settings)
    switch planner.pauseState {
    case .indefinitely:
      return .paused(until: nil)
    case .until(let end):
      return .paused(until: end)
    case .running:
      guard let next = planner.next else { return .idle }
      return now >= next.start ? .onBreak(next) : .waiting(next)
    }
  }

  public mutating func advance(to now: Date, settings: Settings) {
    if case .until(let end) = pauseState, now >= end {
      resume(at: end, settings: settings)
    }
    guard pauseState == .running else { return }
    while let current = next, now >= current.end(settings) {
      let end = current.end(settings)
      if now.timeIntervalSince(end) > Planner.horizon {
        reset(at: now, settings: settings)
        return
      }
      planNext(after: end, settings: settings)
    }
  }

  public mutating func reset(at now: Date, settings: Settings) {
    breakNumber = 0
    pauseState = .running
    planNext(after: now, settings: settings)
  }

  public mutating func finish(at now: Date, settings: Settings) {
    guard pauseState == .running else { return }
    planNext(after: now, settings: settings)
  }

  public mutating func postpone(at now: Date, settings: Settings) {
    guard pauseState == .running, let current = next else { return }
    next = PlannedBreak(
      kind: current.kind,
      start: now.addingTimeInterval(settings.postponeTime(current.kind)),
      scheduledAt: now,
      sequence: current.sequence,
      postpones: current.postpones + 1
    )
  }

  public mutating func skipToMini(at now: Date, settings: Settings) {
    guard pauseState == .running else { return }
    if settings.microbreak && settings.longBreak && breakNumber % settings.longBreakEvery == 0 {
      breakNumber = 1
    }
    schedule(.mini, at: now, from: now)
  }

  public mutating func skipToLong(at now: Date, settings: Settings) {
    guard pauseState == .running else { return }
    if settings.microbreak && settings.longBreak {
      breakNumber = settings.longBreakEvery
    }
    schedule(.long, at: now, from: now)
  }

  public mutating func pause(until end: Date?) {
    breakNumber = 0
    next = nil
    if let end {
      pauseState = .until(end)
    } else {
      pauseState = .indefinitely
    }
  }

  public mutating func resume(at now: Date, settings: Settings) {
    pauseState = .running
    planNext(after: now, settings: settings)
  }

  public func upcoming(from now: Date, settings: Settings, limit: Int) -> [PlannedBreak] {
    var planner = self
    planner.advance(to: now, settings: settings)
    if case .until(let end) = planner.pauseState {
      planner.advance(to: end, settings: settings)
    }
    guard planner.pauseState == .running else { return [] }
    let horizonEnd = now.addingTimeInterval(Planner.horizon)
    var result: [PlannedBreak] = []
    while let current = planner.next, result.count < limit, current.start <= horizonEnd {
      if current.start > now {
        result.append(current)
      }
      planner.planNext(after: current.end(settings), settings: settings)
    }
    return result
  }

  public func notices(from now: Date, settings: Settings) -> [Notice] {
    var notices: [Notice] = []
    if case .paused(let until?) = phase(at: now, settings: settings) {
      notices.append(Notice(id: "resume", date: until, content: .resume))
    }
    notices += upcoming(from: now, settings: settings, limit: Planner.noticeLimit - notices.count)
      .map { Notice(id: $0.id, date: $0.start, content: .breakStart($0)) }
    return notices
  }

  public func longBreakAfterMinis(settings: Settings) -> Int? {
    guard let next, next.kind == .mini, settings.longBreak, settings.microbreak else { return nil }
    let every = settings.longBreakEvery
    return every - breakNumber % every
  }

  public func progress(at now: Date) -> Double {
    guard let next else { return 0 }
    let total = next.start.timeIntervalSince(next.scheduledAt)
    guard total > 0 else { return 1 }
    return min(1, max(0, now.timeIntervalSince(next.scheduledAt) / total))
  }

  private mutating func planNext(after date: Date, settings: Settings) {
    let interval = settings.interval
    switch (settings.microbreak, settings.longBreak) {
    case (true, true):
      breakNumber += 1
      let kind: BreakKind = breakNumber % settings.longBreakEvery == 0 ? .long : .mini
      schedule(kind, at: date.addingTimeInterval(interval), from: date)
    case (true, false):
      schedule(.mini, at: date.addingTimeInterval(interval), from: date)
    case (false, true):
      schedule(.long, at: date.addingTimeInterval(interval * Double(settings.longBreakEvery)), from: date)
    case (false, false):
      next = nil
    }
  }

  private mutating func schedule(_ kind: BreakKind, at start: Date, from date: Date) {
    let sequence: Int
    switch kind {
    case .mini:
      sequence = miniSequence
      miniSequence += 1
    case .long:
      sequence = longSequence
      longSequence += 1
    }
    next = PlannedBreak(kind: kind, start: start, scheduledAt: date, sequence: sequence, postpones: 0)
  }
}
