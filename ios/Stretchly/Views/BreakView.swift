import StretchlyCore
import SwiftUI

struct BreakView: View {
  let plannedBreak: PlannedBreak
  @Environment(AppModel.self) private var model
  @Environment(Localizer.self) private var localizer

  var body: some View {
    let settings = model.settings
    let theme = Theme.matching(settings.mainColor)
    let end = plannedBreak.end(settings)
    GeometryReader { proxy in
      VStack(spacing: 0) {
        VStack(spacing: 0) {
          idea(settings.ideas ? model.idea(for: plannedBreak) : nil)
          ProgressBar(start: plannedBreak.start, end: end, width: min(proxy.size.width, proxy.size.height) * 0.5)
            .padding(.top, 50)
          TimelineView(.periodic(from: plannedBreak.start, by: 1)) { context in
            Text(localizer.remaining(end.timeIntervalSince(context.date)))
              .font(StretchlyFont.light(16, relativeTo: .callout))
              .tracking(0.2)
              .padding(.top, 20)
              .accessibilityHidden(true)
          }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 100)
        .frame(maxWidth: .infinity)
        .frame(height: proxy.size.height * 0.85)
        TimelineView(.periodic(from: plannedBreak.start, by: 1)) { context in
          actions(BreakRules.moment(of: plannedBreak, at: context.date, settings: settings), theme: theme)
        }
        .frame(height: proxy.size.height * 0.10)
        Spacer(minLength: 0)
      }
    }
    .foregroundStyle(theme.foreground)
    .background(theme.color.ignoresSafeArea())
    .background {
      Button("", action: model.endBreakShortcut)
        .keyboardShortcut("x", modifiers: .command)
        .opacity(0)
        .accessibilityHidden(true)
    }
    .statusBarHidden()
    .persistentSystemOverlays(.hidden)
  }

  @ViewBuilder
  private func idea(_ idea: Idea?) -> some View {
    switch plannedBreak.kind {
    case .mini:
      if let text = idea?.text, !text.isEmpty {
        Text(text)
          .font(StretchlyFont.light(30, relativeTo: .title))
          .tracking(0.44)
          .lineSpacing(5)
      }
    case .long:
      if let title = idea?.title, !title.isEmpty {
        Text(title)
          .font(StretchlyFont.light(36, relativeTo: .largeTitle))
          .tracking(0.52)
      }
      if let text = idea?.text, !text.isEmpty {
        Text(text)
          .font(StretchlyFont.light(24, relativeTo: .title2))
          .tracking(0.35)
          .padding(.top, 60)
      }
    }
  }

  private func actions(_ moment: BreakMoment, theme: Theme) -> some View {
    HStack(spacing: 56) {
      if moment.canPostpone {
        BreakAction(title: localizer.t("break.postpone"), icon: "break-postpone", theme: theme, action: model.postpone)
          .transition(.opacity)
      }
      if moment.canSkip {
        BreakAction(title: localizer.t("break.skip"), icon: "break-skip", theme: theme, action: model.skip)
          .transition(.opacity)
      }
    }
    .animation(.easeOut(duration: 0.3), value: moment.canPostpone)
    .animation(.easeOut(duration: 0.3), value: moment.canSkip)
  }
}

private struct BreakAction: View {
  let title: String
  let icon: String
  let theme: Theme
  let action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 20) {
        Text(title)
        Image(icon)
          .resizable()
          .renderingMode(.template)
          .frame(width: 20, height: 20)
          .accessibilityHidden(true)
      }
      .font(StretchlyFont.light(18, relativeTo: .body))
      .tracking(0.26)
      .foregroundStyle(isHovered && !theme.usesDarkText ? Color.stretchlyHover : theme.foreground)
      .padding(.vertical, 12)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
  }
}
