import SwiftUI

struct WelcomeView: View {
  @Environment(AppModel.self) private var model
  @Environment(Localizer.self) private var localizer
  @Environment(\.openURL) private var openURL

  var body: some View {
    GeometryReader { proxy in
      VStack(spacing: 0) {
        Logotype()
          .padding(.top, 48)
        Text(localizer.t("welcome.breakTimeReminderApp"))
          .font(StretchlyFont.light(20, relativeTo: .title3))
          .padding(.top, 8)
        languages
          .frame(width: proxy.size.width * 0.7, height: proxy.size.height * 0.5)
          .padding(.top, 60)
        Spacer(minLength: 24)
        HStack(alignment: .bottom) {
          Button(localizer.t("welcome.viewTutorial")) {
            openURL(URL(string: "https://hovancik.net/stretchly/about")!)
            finish(openingPreferences: false)
          }
          Spacer()
          VStack(alignment: .trailing, spacing: 16) {
            Button(localizer.t("welcome.openPreferences")) { finish(openingPreferences: true) }
            Button(localizer.t("welcome.getStarted")) { finish(openingPreferences: false) }
              .buttonStyle(StretchlyButtonStyle(isPrimary: true))
              .keyboardShortcut(.defaultAction)
          }
        }
        .buttonStyle(StretchlyButtonStyle())
        .padding(.horizontal, proxy.size.width * 0.04)
        .padding(.bottom, 32)
      }
      .frame(maxWidth: .infinity)
    }
    .foregroundStyle(Color.stretchlyText)
    .background(Color.stretchlyBackground.ignoresSafeArea())
  }

  private var languages: some View {
    ScrollViewReader { reader in
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(localizer.languages) { language in
            Button {
              model.update { $0.language = language.code }
            } label: {
              Text(language.name)
                .font(.system(size: 17))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(language.code == model.settings.language ? Color.stretchlySelection : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(language.code == model.settings.language ? .isSelected : [])
            .id(language.code)
          }
        }
        .padding(.vertical, 8)
      }
      .background(Color.stretchlyControl)
      .overlay { Rectangle().strokeBorder(Color.stretchlyControlBorder, lineWidth: 0.5) }
      .onAppear { reader.scrollTo(model.settings.language, anchor: .center) }
    }
  }

  private func finish(openingPreferences: Bool) {
    Task { await model.completeWelcome(openingPreferences: openingPreferences) }
  }
}
