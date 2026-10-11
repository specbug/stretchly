import SwiftUI

struct SettingsPane: View {
  @Environment(AppModel.self) private var model
  @Environment(Localizer.self) private var localizer
  @State private var isConfirmingRestore = false

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Toggle(localizer.t("preferences.settings.showIdeas"), isOn: model.binding(\.ideas))
      Toggle(localizer.t("preferences.settings.monitorDnd"), isOn: Binding(
        get: { !model.settings.monitorDnd },
        set: { value in model.update { $0.monitorDnd = !value } }
      ))
      Rule()
      HStack(spacing: 12) {
        Text(localizer.t("preferences.settings.language"))
        Picker(localizer.t("preferences.settings.language"), selection: model.binding(\.language)) {
          ForEach(localizer.languages) { language in
            Text(language.name).tag(language.code)
          }
        }
        .pickerStyle(.menu)
        .tint(Color.stretchlyText)
        .labelsHidden()
      }
      Rule()
      Button(localizer.t("preferences.settings.restoreDefaults")) { isConfirmingRestore = true }
        .buttonStyle(StretchlyButtonStyle())
    }
    .padding(.leading, 64)
    .alert(localizer.t("main.restoreDefaults"), isPresented: $isConfirmingRestore) {
      Button(localizer.t("main.continue"), role: .destructive, action: model.restoreDefaults)
      Button(localizer.t("main.cancel"), role: .cancel) {}
    } message: {
      Text(localizer.t("main.warning"))
    }
  }
}
