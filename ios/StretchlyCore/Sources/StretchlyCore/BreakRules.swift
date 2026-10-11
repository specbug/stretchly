import Foundation

public struct BreakMoment: Equatable, Sendable {
  public let elapsed: TimeInterval
  public let remaining: TimeInterval
  public let canPostpone: Bool
  public let canSkip: Bool

  public var isOver: Bool { remaining <= 0 }
}

public enum BreakRules {
  public static func canPostpone(_ postponable: Bool, passedPercent: Double, postponablePercent: Double) -> Bool {
    postponable && passedPercent <= postponablePercent
  }

  public static func canSkip(strict: Bool, postponable: Bool, passedPercent: Double, postponablePercent: Double) -> Bool {
    !((postponable && passedPercent <= postponablePercent) || strict)
  }

  public static func isPostponable(_ plannedBreak: PlannedBreak, settings: Settings) -> Bool {
    let limit = settings.postponesLimit(plannedBreak.kind)
    return settings.isPostponeEnabled(plannedBreak.kind) && plannedBreak.postpones < limit && limit > 0
  }

  public static func moment(of plannedBreak: PlannedBreak, at now: Date, settings: Settings) -> BreakMoment {
    let kind = plannedBreak.kind
    let duration = settings.duration(kind)
    let elapsed = max(0, now.timeIntervalSince(plannedBreak.start))
    let passedPercent = duration > 0 ? elapsed / duration * 100 : 100
    let postponable = isPostponable(plannedBreak, settings: settings)
    let postponablePercent = settings.postponablePercent(kind)
    let isOver = elapsed >= duration
    return BreakMoment(
      elapsed: elapsed,
      remaining: max(0, duration - elapsed),
      canPostpone: !isOver && canPostpone(postponable, passedPercent: passedPercent, postponablePercent: postponablePercent),
      canSkip: !isOver && canSkip(strict: settings.isStrict(kind), postponable: postponable, passedPercent: passedPercent, postponablePercent: postponablePercent)
    )
  }
}

public enum PauseOption: CaseIterable, Sendable {
  case thirtyMinutes
  case oneHour
  case twoHours
  case fiveHours
  case untilMorning
  case indefinitely

  public func end(from now: Date, morningHour: Int, calendar: Calendar = .current) -> Date? {
    switch self {
    case .thirtyMinutes: return now.addingTimeInterval(30 * 60)
    case .oneHour: return now.addingTimeInterval(60 * 60)
    case .twoHours: return now.addingTimeInterval(2 * 60 * 60)
    case .fiveHours: return now.addingTimeInterval(5 * 60 * 60)
    case .untilMorning: return Morning.next(after: now, hour: morningHour, calendar: calendar)
    case .indefinitely: return nil
    }
  }
}

public enum Morning {
  public static func next(after date: Date, hour: Int, calendar: Calendar = .current) -> Date {
    let startOfDay = calendar.startOfDay(for: date)
    let morning = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay) ?? startOfDay
    guard calendar.component(.hour, from: date) >= hour else { return morning }
    return calendar.date(byAdding: .day, value: 1, to: morning) ?? morning.addingTimeInterval(24 * 60 * 60)
  }
}
