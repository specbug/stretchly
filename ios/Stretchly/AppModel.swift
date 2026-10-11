import Foundation
import Observation
import StretchlyCore
import SwiftUI
import UserNotifications

@MainActor
@Observable
final class AppModel {
  private(set) var settings: Settings
  private(set) var planner: Planner
  private(set) var activeBreak: PlannedBreak?
  private(set) var notificationStatus = UNAuthorizationStatus.notDetermined
  var isShowingPreferences = false

  let localizer: Localizer
  @ObservationIgnored let sounds = SoundPlayer()
  @ObservationIgnored private let notifications = BreakNotifications()
  @ObservationIgnored private var transition: Task<Void, Never>?
  @ObservationIgnored private var pendingSchedule: Task<Void, Never>?
  @ObservationIgnored private var savedPlanner: Planner?
  @ObservationIgnored private var isActive = false

  private enum Keys {
    static let settings = "settings"
    static let planner = "planner"
  }

  init() {
    let storedSettings = AppModel.load(Settings.self, key: Keys.settings)
    var settings = storedSettings ?? Settings()
    if storedSettings == nil {
      settings.language = Localizer.preferredLanguage()
    }
    self.settings = settings
    localizer = Localizer(language: settings.language)
    let storedPlanner = AppModel.load(Planner.self, key: Keys.planner)
    planner = storedPlanner ?? Planner()
    savedPlanner = storedPlanner
    if storedPlanner == nil {
      planner.reset(at: .now, settings: settings)
    }
    notifications.registerCategories(localizer: localizer)
  }

  func binding<Value: Equatable>(_ keyPath: WritableKeyPath<Settings, Value>) -> Binding<Value> {
    Binding(
      get: { self.settings[keyPath: keyPath] },
      set: { value in self.update { $0[keyPath: keyPath] = value } }
    )
  }

  func update(_ change: (inout Settings) -> Void) {
    let previous = settings
    var updated = settings
    change(&updated)
    guard updated != previous else { return }
    settings = updated
    if updated.language != previous.language {
      localizer.use(updated.language)
      notifications.registerCategories(localizer: localizer)
    }
    if updated.scheduleDiffers(from: previous) {
      planner.reset(at: .now, settings: updated)
    }
    AppModel.save(updated, key: Keys.settings)
    refresh()
  }

  func refresh(now: Date = .now) {
    let previous = activeBreak
    planner.advance(to: now, settings: settings)
    if case .onBreak(let current) = planner.phase(at: now, settings: settings) {
      activeBreak = current
    } else {
      activeBreak = nil
    }
    if let previous, activeBreak?.id != previous.id, isActive,
       abs(now.timeIntervalSince(previous.end(settings))) < 2 {
      playBreakSound()
    }
    if planner != savedPlanner {
      AppModel.save(planner, key: Keys.planner)
      savedPlanner = planner
    }
    planTransition(now: now)
    scheduleNotificationsSoon()
  }

  func sceneBecameActive() {
    isActive = true
    notifications.clearDelivered()
    refresh()
    Task { notificationStatus = await notifications.authorizationStatus() }
  }

  func sceneEnteredBackground() {
    isActive = false
    transition?.cancel()
    scheduleNotificationsNow()
  }

  func idea(for plannedBreak: PlannedBreak) -> Idea {
    IdeaDeck.idea(for: plannedBreak, seed: planner.seed, translator: localizer.translator)
  }

  func moment(at now: Date = .now) -> BreakMoment? {
    activeBreak.map { BreakRules.moment(of: $0, at: now, settings: settings) }
  }

  func postpone() {
    guard moment()?.canPostpone == true else { return }
    activeBreak = nil
    planner.postpone(at: .now, settings: settings)
    refresh()
  }

  func skip() {
    guard moment()?.canSkip == true else { return }
    activeBreak = nil
    planner.finish(at: .now, settings: settings)
    refresh()
  }

  func endBreakShortcut() {
    guard let moment = moment() else { return }
    if moment.canPostpone {
      postpone()
    } else if moment.canSkip {
      skip()
    }
  }

  func skipToNext(_ kind: BreakKind) {
    switch kind {
    case .mini: planner.skipToMini(at: .now, settings: settings)
    case .long: planner.skipToLong(at: .now, settings: settings)
    }
    refresh()
  }

  func pause(_ option: PauseOption) {
    planner.pause(until: option.end(from: .now, morningHour: settings.morningHour))
    refresh()
  }

  func resume() {
    planner.resume(at: .now, settings: settings)
    refresh()
  }

  func resetBreaks() {
    planner.reset(at: .now, settings: settings)
    refresh()
  }

  func restoreDefaults() {
    var defaults = Settings()
    defaults.language = settings.language
    defaults.isFirstRun = false
    update { $0 = defaults }
    resetBreaks()
  }

  func completeWelcome(openingPreferences: Bool) async {
    update { $0.isFirstRun = false }
    resetBreaks()
    await notifications.authorize()
    notificationStatus = await notifications.authorizationStatus()
    scheduleNotificationsNow()
    isShowingPreferences = openingPreferences
  }

  func handleNotificationResponse(action: String, breakID: String?) {
    refresh()
    if action == NotificationKeys.postponeAction,
       let breakID, planner.next?.id == breakID,
       moment()?.canPostpone == true {
      postpone()
    }
    scheduleNotificationsNow()
  }

  func playPreview(_ sound: BreakSound) {
    sounds.play(sound.id)
  }

  private func playBreakSound() {
    guard !settings.silentNotifications else { return }
    sounds.play(settings.longBreakAudio)
  }

  private func planTransition(now: Date) {
    transition?.cancel()
    guard isActive else { return }
    let next: Date?
    switch planner.phase(at: now, settings: settings) {
    case .onBreak(let current): next = current.end(settings)
    case .waiting(let upcoming): next = upcoming.start
    case .paused(let until): next = until
    case .idle: next = nil
    }
    guard let next else { return }
    transition = Task { [weak self] in
      try? await Task.sleep(for: .seconds(max(0, next.timeIntervalSinceNow)))
      guard !Task.isCancelled else { return }
      self?.refresh()
    }
  }

  private func scheduleNotificationsSoon() {
    pendingSchedule?.cancel()
    pendingSchedule = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(400))
      guard !Task.isCancelled else { return }
      self?.scheduleNotificationsNow()
    }
  }

  private func scheduleNotificationsNow() {
    pendingSchedule?.cancel()
    notifications.schedule(planner: planner, settings: settings, localizer: localizer, now: .now)
  }

  private static func load<Value: Decodable>(_ type: Value.Type, key: String) -> Value? {
    UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(type, from: $0) }
  }

  private static func save<Value: Encodable>(_ value: Value, key: String) {
    guard let data = try? JSONEncoder().encode(value) else { return }
    UserDefaults.standard.set(data, forKey: key)
  }
}
