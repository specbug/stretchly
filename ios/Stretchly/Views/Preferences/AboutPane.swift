import SwiftUI

struct AboutPane: View {
  @Environment(Localizer.self) private var localizer

  private var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
  }

  var body: some View {
    VStack(spacing: 28) {
      VStack(spacing: 8) {
        Logotype()
        Text(localizer.t("preferences.about.tagline"))
          .font(StretchlyFont.light(20, relativeTo: .title3))
      }
      Text(localizer.t("preferences.about.version") + version)
      HStack(alignment: .top, spacing: 16) {
        Image("home")
          .resizable()
          .frame(width: 32, height: 32)
          .accessibilityHidden(true)
        Text(linked(localizer.t("preferences.about.learnMore"), localizer.t("preferences.about.ourWebsite"), "https://hovancik.net/stretchly/", localizer.t("preferences.about.dot")))
          .frame(maxWidth: 420, alignment: .leading)
      }
      Text(linked(localizer.t("preferences.about.developedBy") + " ", localizer.t("preferences.about.janH"), "https://hovancik.net/", ""))
      Text(linked(localizer.t("preferences.about.designedBy") + " (", "www.colinshanley.com", "http://www.colinshanley.com/", ")"))
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .tint(Color.stretchlyAccent)
  }

  private func linked(_ prefix: String, _ label: String, _ url: String, _ suffix: String) -> AttributedString {
    var link = AttributedString(label)
    link.link = URL(string: url)
    return AttributedString(prefix) + link + AttributedString(suffix)
  }
}
