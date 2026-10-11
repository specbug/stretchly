import Foundation

public enum BreakKind: String, Codable, CaseIterable, Sendable {
  case mini
  case long
}

public struct Settings: Codable, Hashable, Sendable {
  public var microbreak = true
  public var microbreakDuration = 20_000
  public var microbreakInterval = 600_000
  public var microbreakPostpone = true
  public var microbreakPostponeTime = 120_000
  public var microbreakPostponesLimit = 1
  public var microbreakPostponableDurationPercent = 30
  public var microbreakStrictMode = false
  public var longBreak = true
  public var breakDuration = 300_000
  public var breakInterval = 2
  public var breakPostpone = true
  public var breakPostponeTime = 300_000
  public var breakPostponesLimit = 1
  public var breakPostponableDurationPercent = 30
  public var breakStrictMode = false
  public var ideas = true
  public var monitorDnd = true
  public var language = "en"
  public var mainColor = "#478484"
  public var silentNotifications = false
  public var longBreakAudio = "crystal-glass"
  public var morningHour = 6
  public var isFirstRun = true

  public init() {}

  enum CodingKeys: String, CodingKey {
    case microbreak
    case microbreakDuration
    case microbreakInterval
    case microbreakPostpone
    case microbreakPostponeTime
    case microbreakPostponesLimit
    case microbreakPostponableDurationPercent
    case microbreakStrictMode
    case longBreak = "break"
    case breakDuration
    case breakInterval
    case breakPostpone
    case breakPostponeTime
    case breakPostponesLimit
    case breakPostponableDurationPercent
    case breakStrictMode
    case ideas
    case monitorDnd
    case language
    case mainColor
    case silentNotifications
    case longBreakAudio
    case morningHour
    case isFirstRun
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let d = Settings()
    microbreak = try c.decodeIfPresent(Bool.self, forKey: .microbreak) ?? d.microbreak
    microbreakDuration = try c.decodeIfPresent(Int.self, forKey: .microbreakDuration) ?? d.microbreakDuration
    microbreakInterval = try c.decodeIfPresent(Int.self, forKey: .microbreakInterval) ?? d.microbreakInterval
    microbreakPostpone = try c.decodeIfPresent(Bool.self, forKey: .microbreakPostpone) ?? d.microbreakPostpone
    microbreakPostponeTime = try c.decodeIfPresent(Int.self, forKey: .microbreakPostponeTime) ?? d.microbreakPostponeTime
    microbreakPostponesLimit = try c.decodeIfPresent(Int.self, forKey: .microbreakPostponesLimit) ?? d.microbreakPostponesLimit
    microbreakPostponableDurationPercent = try c.decodeIfPresent(Int.self, forKey: .microbreakPostponableDurationPercent) ?? d.microbreakPostponableDurationPercent
    microbreakStrictMode = try c.decodeIfPresent(Bool.self, forKey: .microbreakStrictMode) ?? d.microbreakStrictMode
    longBreak = try c.decodeIfPresent(Bool.self, forKey: .longBreak) ?? d.longBreak
    breakDuration = try c.decodeIfPresent(Int.self, forKey: .breakDuration) ?? d.breakDuration
    breakInterval = try c.decodeIfPresent(Int.self, forKey: .breakInterval) ?? d.breakInterval
    breakPostpone = try c.decodeIfPresent(Bool.self, forKey: .breakPostpone) ?? d.breakPostpone
    breakPostponeTime = try c.decodeIfPresent(Int.self, forKey: .breakPostponeTime) ?? d.breakPostponeTime
    breakPostponesLimit = try c.decodeIfPresent(Int.self, forKey: .breakPostponesLimit) ?? d.breakPostponesLimit
    breakPostponableDurationPercent = try c.decodeIfPresent(Int.self, forKey: .breakPostponableDurationPercent) ?? d.breakPostponableDurationPercent
    breakStrictMode = try c.decodeIfPresent(Bool.self, forKey: .breakStrictMode) ?? d.breakStrictMode
    ideas = try c.decodeIfPresent(Bool.self, forKey: .ideas) ?? d.ideas
    monitorDnd = try c.decodeIfPresent(Bool.self, forKey: .monitorDnd) ?? d.monitorDnd
    language = try c.decodeIfPresent(String.self, forKey: .language) ?? d.language
    mainColor = try c.decodeIfPresent(String.self, forKey: .mainColor) ?? d.mainColor
    silentNotifications = try c.decodeIfPresent(Bool.self, forKey: .silentNotifications) ?? d.silentNotifications
    longBreakAudio = try c.decodeIfPresent(String.self, forKey: .longBreakAudio) ?? d.longBreakAudio
    morningHour = try c.decodeIfPresent(Int.self, forKey: .morningHour) ?? d.morningHour
    isFirstRun = try c.decodeIfPresent(Bool.self, forKey: .isFirstRun) ?? d.isFirstRun
  }
}

public extension Settings {
  var interval: TimeInterval { seconds(microbreakInterval) }

  var longBreakEvery: Int { breakInterval + 1 }

  var hasAnyBreak: Bool { microbreak || longBreak }

  func isEnabled(_ kind: BreakKind) -> Bool {
    kind == .mini ? microbreak : longBreak
  }

  func duration(_ kind: BreakKind) -> TimeInterval {
    seconds(kind == .mini ? microbreakDuration : breakDuration)
  }

  func postponeTime(_ kind: BreakKind) -> TimeInterval {
    seconds(kind == .mini ? microbreakPostponeTime : breakPostponeTime)
  }

  func isPostponeEnabled(_ kind: BreakKind) -> Bool {
    kind == .mini ? microbreakPostpone : breakPostpone
  }

  func postponesLimit(_ kind: BreakKind) -> Int {
    kind == .mini ? microbreakPostponesLimit : breakPostponesLimit
  }

  func postponablePercent(_ kind: BreakKind) -> Double {
    Double(kind == .mini ? microbreakPostponableDurationPercent : breakPostponableDurationPercent)
  }

  func isStrict(_ kind: BreakKind) -> Bool {
    kind == .mini ? microbreakStrictMode : breakStrictMode
  }

  func scheduleDiffers(from other: Settings) -> Bool {
    microbreak != other.microbreak || longBreak != other.longBreak
  }

  private func seconds(_ milliseconds: Int) -> TimeInterval {
    TimeInterval(milliseconds) / 1000
  }
}
