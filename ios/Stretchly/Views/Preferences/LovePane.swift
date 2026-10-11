import SwiftUI

struct LovePane: View {
  @Environment(Localizer.self) private var localizer
  @Environment(\.openURL) private var openURL

  var body: some View {
    HStack(alignment: .top, spacing: 40) {
      Image("logo")
        .resizable()
        .scaledToFit()
        .frame(width: 160)
        .padding(.top, 24)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 20) {
        Text(localizer.t("preferences.heart.loveStretchly"))
          .font(StretchlyFont.light(44, relativeTo: .largeTitle))
          .tracking(-0.4)
        Text(localizer.t("preferences.heart.desc1"))
          .font(StretchlyFont.light(20, relativeTo: .title3))
        Text(localizer.t("preferences.heart.desc2"))
          .font(StretchlyFont.light(20, relativeTo: .title3))
        Button(localizer.t("preferences.heart.becomeContributor")) {
          openURL(URL(string: "https://hovancik.net/stretchly/sponsor")!)
        }
        .buttonStyle(StretchlyButtonStyle())
        .padding(.top, 16)
      }
      .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 16)
  }
}
