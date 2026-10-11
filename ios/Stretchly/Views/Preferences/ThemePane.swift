import StretchlyCore
import SwiftUI

struct ThemePane: View {
  @Environment(AppModel.self) private var model
  @Environment(Localizer.self) private var localizer

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PaneSection(title: localizer.t("preferences.theme.appearance")) {
        ForEach(Theme.all) { theme in
          ThemeRow(theme: theme, name: localizer.t(theme.nameKey), isSelected: Theme.matching(model.settings.mainColor) == theme) {
            model.update { $0.mainColor = theme.id }
          }
        }
      }
      Rule()
      PaneSection(title: localizer.t("preferences.theme.sounds")) {
        Toggle(localizer.t("preferences.theme.enableSounds"), isOn: Binding(
          get: { !model.settings.silentNotifications },
          set: { value in model.update { $0.silentNotifications = !value } }
        ))
        ForEach(BreakSound.all) { sound in
          HStack(spacing: 16) {
            Button {
              model.update { $0.longBreakAudio = sound.id }
            } label: {
              HStack(spacing: 10) {
                RadioMark(isSelected: model.settings.longBreakAudio == sound.id)
                Text(localizer.t(sound.nameKey))
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(model.settings.longBreakAudio == sound.id ? .isSelected : [])
            Button {
              model.playPreview(sound)
            } label: {
              Image("speaker")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .accessibilityLabel(localizer.t(sound.nameKey))
          }
        }
      }
    }
  }
}

private struct ThemeRow: View {
  let theme: Theme
  let name: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 17) {
        ZStack {
          Rectangle().fill(theme.color)
          if isSelected {
            Image(systemName: "checkmark")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(theme.foreground)
          }
        }
        .frame(width: 35, height: 35)
        .padding(5)
        .background(Color.stretchlySwatchBorder)
        .overlay { Rectangle().strokeBorder(Color.stretchlyControlBorder, lineWidth: 0.5) }
        Text(name)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
