import SwiftUI
import UserNotifications

@main
struct StretchlyApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(appDelegate.model)
        .environment(appDelegate.model.localizer)
    }
  }
}

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  lazy var model = AppModel()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    let isResume = notification.request.identifier == NotificationKeys.resumeIdentifier
    await MainActor.run { model.refresh() }
    return isResume ? [.banner, .list] : []
  }

  nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    let action = response.actionIdentifier
    let breakID = response.notification.request.content.userInfo[NotificationKeys.breakIDKey] as? String
    await MainActor.run { model.handleNotificationResponse(action: action, breakID: breakID) }
  }
}
