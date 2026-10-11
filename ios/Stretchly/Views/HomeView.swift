import StretchlyCore
import SwiftUI

struct HomeView: View {
  @Environment(AppModel.self) private var model
  @Environment(Localizer.self) private var localizer
  @Environment(\.openURL) private var openURL

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      Logotype()
      Text(localizer.t("welcome.breakTimeReminderApp"))
        .font(StretchlyFont.light(20, relativeTo: .title3))
        .padding(.top, 8)
      status
        .padding(.top, 72)
      actions
        .padding(.top, 56)
      Spacer()
      if model.notificationStatus == .denied {
        notificationsOff
          .padding(.bottom, 32)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 24)
    .multilineTextAlignment(.center)
    .foregroundStyle(Color.stretchlyText)
    .background(Color.stretchlyBackground.ignoresSafeArea())
    .overlay(alignment: .topTrailing) {
      Button {
        model.isShowingPreferences = true
      } label: {
        Image("nav-settings")
          .resizable()
          .frame(width: 28, height: 28)
          .padding(12)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .hoverEffect()
      .keyboardShortcut(",", modifiers: .command)
      .accessibilityLabel(localizer.t("main.preferences"))
      .padding(12)
    }
  }

  @ViewBuilder
  private var status: some View {
    switch model.planner.phase(at: .now, settings: model.settings) {
    case .waiting(let upcoming):
      TimelineView(.periodic(from: minuteAnchor(for: upcoming.start), by: 60)) { context in
        VStack(spacing: 20) {
          Text(nextBreakLine(upcoming, now: context.date))
            .font(StretchlyFont.light(26, relativeTo: .title2))
          ProgressBar(start: upcoming.scheduledAt, end: upcoming.start, width: 280)
          if let count = model.planner.longBreakAfterMinis(settings: model.settings) {
            Text(localizer.t("statusMessages.nextLongBreak") + " " + localizer.t("statusMessages.afterMiniBreak", count: Double(count)))
              .font(StretchlyFont.light(17))
          }
        }
      }
    case .paused(let until?):
      TimelineView(.periodic(from: minuteAnchor(for: until), by: 60)) { context in
        Text(localizer.t("statusMessages.paused") + " - " + localizer.t("statusMessages.resuming") + " " + localizer.inAbout(until.timeIntervalSince(context.date)))
          .font(StretchlyFont.light(26, relativeTo: .title2))
      }
    case .paused(nil):
      Text(localizer.t("statusMessages.paused") + " " + localizer.t("statusMessages.indefinitely"))
        .font(StretchlyFont.light(26, relativeTo: .title2))
    case .onBreak, .idle:
      EmptyView()
    }
  }

  private var actions: some View {
    VStack(spacing: 20) {
      if model.planner.pauseState != .running {
        Button(localizer.t("main.resume"), action: model.resume)
      } else if model.settings.hasAnyBreak {
        Menu(localizer.t("main.skipToTheNext")) {
          if model.settings.microbreak {
            Button(localizer.t("main.toMicrobreak")) { model.skipToNext(.mini) }
          }
          if model.settings.longBreak {
            Button(localizer.t("main.toBreak")) { model.skipToNext(.long) }
          }
        }
        Menu(localizer.t("main.pause")) {
          Button(localizer.t("utils.minutes", count: 30)) { model.pause(.thirtyMinutes) }
          Button(localizer.t("main.forHour")) { model.pause(.oneHour) }
          Button(localizer.t("main.for2Hours")) { model.pause(.twoHours) }
          Button(localizer.t("main.for5Hours")) { model.pause(.fiveHours) }
          Button(localizer.t("main.untilMorning")) { model.pause(.untilMorning) }
          Divider()
          Button(localizer.t("main.indefinitely")) { model.pause(.indefinitely) }
        }
        Button(localizer.t("main.resetBreaks"), action: model.resetBreaks)
      }
    }
    .font(StretchlyFont.regular(17))
    .buttonStyle(StretchlyButtonStyle())
    .menuStyle(.button)
  }

  private var notificationsOff: some View {
    VStack(spacing: 12) {
      Text(localizer.t("ios.notificationsOff"))
        .font(StretchlyFont.light(16))
        .frame(maxWidth: 420)
      Button(localizer.t("ios.openSettings")) {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
          openURL(url)
        }
      }
      .font(StretchlyFont.regular(16))
      .foregroundStyle(Color.stretchlyAccent)
      .buttonStyle(.plain)
    }
  }

  private func minuteAnchor(for target: Date) -> Date {
    let offset = (target.timeIntervalSinceNow + 30).truncatingRemainder(dividingBy: 60)
    return Date.now.addingTimeInterval(offset > 0 ? offset - 60 : offset)
  }

  private func nextBreakLine(_ upcoming: PlannedBreak, now: Date) -> String {
    let key = upcoming.kind == .mini ? "statusMessages.nextMiniBreak" : "statusMessages.nextLongBreak"
    return localizer.t(key) + " " + localizer.inAbout(upcoming.start.timeIntervalSince(now))
  }
}
