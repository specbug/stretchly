import SwiftUI

struct PreferencesView: View {
  enum Pane: String, CaseIterable {
    case settings, schedule, theme, about, heart
  }

  @Environment(Localizer.self) private var localizer
  @Environment(\.dismiss) private var dismiss
  @State private var pane = Pane.settings

  var body: some View {
    VStack(spacing: 0) {
      header
      ScrollView {
        content
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 24)
          .padding(.top, 32)
          .padding(.bottom, 56)
      }
    }
    .font(StretchlyFont.regular(17))
    .foregroundStyle(Color.stretchlyText)
    .background(Color.stretchlyBackground.ignoresSafeArea())
    .toggleStyle(StretchlyCheckboxStyle())
  }

  private var header: some View {
    VStack(spacing: 0) {
      ZStack {
        Text(localizer.t("preferences.title"))
          .font(StretchlyFont.regular(15))
        HStack {
          Spacer()
          Button(localizer.t("ios.done")) { dismiss() }
            .font(StretchlyFont.regular(15))
            .foregroundStyle(Color.stretchlyAccent)
            .keyboardShortcut(.cancelAction)
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 12)
      .padding(.bottom, 4)
      HStack(alignment: .bottom, spacing: 16) {
        ForEach([Pane.settings, .schedule, .theme, .about], id: \.self, content: tab)
        Spacer(minLength: 16)
        tab(.heart)
      }
      .padding(.horizontal, 16)
    }
    .background(LinearGradient(colors: [.stretchlyNavTop, .stretchlyNavBottom], startPoint: .top, endPoint: .bottom))
    .overlay(alignment: .bottom) { Rule() }
  }

  private func tab(_ item: Pane) -> some View {
    Button {
      pane = item
    } label: {
      VStack(spacing: 4) {
        Image("nav-\(item.rawValue)")
          .resizable()
          .frame(width: 32, height: 32)
          .accessibilityHidden(true)
        Text(localizer.t("preferences.nav.\(item.rawValue)"))
          .font(StretchlyFont.regular(12, relativeTo: .caption))
          .lineLimit(1)
      }
      .padding(.horizontal, 8)
      .frame(minWidth: 64, minHeight: 64)
      .background {
        UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4)
          .fill(Color.black.opacity(pane == item ? 0.1 : 0))
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(pane == item ? .isSelected : [])
  }

  @ViewBuilder
  private var content: some View {
    switch pane {
    case .settings: SettingsPane()
    case .schedule: SchedulePane()
    case .theme: ThemePane()
    case .about: AboutPane()
    case .heart: LovePane()
    }
  }
}

struct PaneSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 24) {
      Text(title)
        .multilineTextAlignment(.trailing)
        .containerRelativeFrame(.horizontal, alignment: .trailing) { width, _ in width * 0.22 }
      VStack(alignment: .leading, spacing: 16) {
        content
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct InfoText: View {
  let text: String

  var body: some View {
    Text(text)
      .font(StretchlyFont.regular(15))
      .frame(maxWidth: 380, alignment: .leading)
      .fixedSize(horizontal: false, vertical: true)
  }
}

struct SliderRow: View {
  let title: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double
  let output: String

  var body: some View {
    HStack(spacing: 16) {
      Text(title)
        .frame(minWidth: 90, alignment: .leading)
      Slider(value: $value, in: range, step: step)
        .tint(Color.stretchlyAccent)
        .frame(width: 240)
        .accessibilityLabel(title)
        .accessibilityValue(output)
      Text(output)
        .monospacedDigit()
        .lineLimit(1)
    }
  }
}
