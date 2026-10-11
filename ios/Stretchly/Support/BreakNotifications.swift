import Foundation
import StretchlyCore
import UserNotifications

enum NotificationKeys {
  static let postponableCategory = "break-postponable"
  static let breakCategory = "break"
  static let postponeAction = "postpone"
  static let resumeIdentifier = "resume"
  static let breakIDKey = "breakID"
}

@MainActor
final class BreakNotifications {
  private let center = UNUserNotificationCenter.current()
  private var scheduledFingerprint: Int?

  func authorize() async {
    _ = try? await center.requestAuthorization(options: [.alert, .sound])
  }

  func authorizationStatus() async -> UNAuthorizationStatus {
    await center.notificationSettings().authorizationStatus
  }

  func registerCategories(localizer: Localizer) {
    let postpone = UNNotificationAction(identifier: NotificationKeys.postponeAction, title: localizer.t("break.postpone"), options: [])
    center.setNotificationCategories([
      UNNotificationCategory(identifier: NotificationKeys.postponableCategory, actions: [postpone], intentIdentifiers: []),
      UNNotificationCategory(identifier: NotificationKeys.breakCategory, actions: [], intentIdentifiers: [])
    ])
    scheduledFingerprint = nil
  }

  func clearDelivered() {
    center.removeAllDeliveredNotifications()
  }

  func schedule(planner: Planner, settings: Settings, localizer: Localizer, now: Date) {
    let notices = planner.notices(from: now, settings: settings)
    var hasher = Hasher()
    hasher.combine(settings)
    hasher.combine(localizer.translator.language)
    for notice in notices {
      hasher.combine(notice.id)
      hasher.combine(notice.date)
    }
    let fingerprint = hasher.finalize()
    guard fingerprint != scheduledFingerprint else { return }
    scheduledFingerprint = fingerprint

    center.removeAllPendingNotificationRequests()
    for notice in notices {
      let interval = notice.date.timeIntervalSince(now)
      guard interval > 0 else { continue }
      let request = UNNotificationRequest(
        identifier: notice.id,
        content: content(for: notice, planner: planner, settings: settings, localizer: localizer),
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
      )
      center.add(request) { _ in }
    }
  }

  private func content(for notice: Notice, planner: Planner, settings: Settings, localizer: Localizer) -> UNNotificationContent {
    let content = UNMutableNotificationContent()
    switch notice.content {
    case .resume:
      content.title = localizer.t("main.resumingBreaks")
    case .breakStart(let plannedBreak):
      if settings.ideas {
        let idea = IdeaDeck.idea(for: plannedBreak, seed: planner.seed, translator: localizer.translator)
        content.title = idea.title ?? localizer.t("break.title")
        content.body = idea.text
      } else {
        content.title = localizer.t("break.title")
        content.body = localizer.t(plannedBreak.kind == .mini ? "main.toMicrobreak" : "main.toBreak")
      }
      content.categoryIdentifier = BreakRules.isPostponable(plannedBreak, settings: settings)
        ? NotificationKeys.postponableCategory
        : NotificationKeys.breakCategory
      content.threadIdentifier = "breaks"
      content.interruptionLevel = settings.monitorDnd ? .active : .timeSensitive
      content.userInfo = [NotificationKeys.breakIDKey: plannedBreak.id]
    }
    if !settings.silentNotifications {
      content.sound = UNNotificationSound(named: UNNotificationSoundName("\(settings.longBreakAudio).wav"))
    }
    return content
  }
}
