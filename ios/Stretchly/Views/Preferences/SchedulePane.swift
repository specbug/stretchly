import StretchlyCore
import SwiftUI

struct SchedulePane: View {
  @Environment(AppModel.self) private var model
  @Environment(Localizer.self) private var localizer
  @State private var isWarningAboutBothDisabled = false

  var body: some View {
    let settings = model.settings
    VStack(alignment: .leading, spacing: 24) {
      PaneSection(title: localizer.t("preferences.schedule.miniBreaks")) {
        InfoText(text: localizer.t("preferences.schedule.miniBreaksInfo"))
        Toggle(localizer.t("preferences.schedule.enableMiniBreaks"), isOn: enabled(.mini))
        SliderRow(
          title: localizer.t("preferences.schedule.breakFor"),
          value: milliseconds(\.microbreakDuration, unit: 1000),
          range: 10...600,
          step: 10,
          output: localizer.unitValue(seconds: settings.duration(.mini))
        )
        SliderRow(
          title: localizer.t("preferences.schedule.every"),
          value: milliseconds(\.microbreakInterval, unit: 60_000),
          range: 5...65,
          step: 5,
          output: localizer.t("utils.minutes", count: settings.interval / 60)
        )
        Toggle(localizer.t("preferences.schedule.enablePostponeMini"), isOn: model.binding(\.microbreakPostpone))
      }
      Rule()
      PaneSection(title: localizer.t("preferences.schedule.longBreaks")) {
        InfoText(text: localizer.t("preferences.schedule.longBreaksInfo"))
        Toggle(localizer.t("preferences.schedule.enableLongBreaks"), isOn: enabled(.long))
        SliderRow(
          title: localizer.t("preferences.schedule.breakFor"),
          value: milliseconds(\.breakDuration, unit: 60_000),
          range: 1...60,
          step: 1,
          output: localizer.t("utils.minutes", count: settings.duration(.long) / 60)
        )
        SliderRow(
          title: localizer.t("preferences.schedule.every"),
          value: Binding(
            get: { Double(model.settings.breakInterval) },
            set: { value in model.update { $0.breakInterval = Int(value) } }
          ),
          range: 1...30,
          step: 1,
          output: localizer.t("utils.minutes", count: settings.interval * Double(settings.longBreakEvery) / 60)
        )
        Toggle(localizer.t("preferences.schedule.enablePostponeLong"), isOn: model.binding(\.breakPostpone))
      }
      Rule()
      PaneSection(title: localizer.t("preferences.schedule.strictMode")) {
        InfoText(text: localizer.t("preferences.schedule.strictModeInfo"))
        InfoText(text: localizer.t("ios.strictModeInfo"))
        Toggle(localizer.t("preferences.schedule.enableStrictMini"), isOn: model.binding(\.microbreakStrictMode))
        Toggle(localizer.t("preferences.schedule.enableStrictLong"), isOn: model.binding(\.breakStrictMode))
      }
    }
    .alert(localizer.t("preferences.schedule.cantDisableBoth"), isPresented: $isWarningAboutBothDisabled) {
      Button(localizer.t("main.continue"), role: .cancel) {}
    }
  }

  private func enabled(_ kind: BreakKind) -> Binding<Bool> {
    Binding(
      get: { model.settings.isEnabled(kind) },
      set: { value in
        let other: BreakKind = kind == .mini ? .long : .mini
        guard value || model.settings.isEnabled(other) else {
          isWarningAboutBothDisabled = true
          return
        }
        model.update { settings in
          if kind == .mini {
            settings.microbreak = value
          } else {
            settings.longBreak = value
          }
        }
      }
    )
  }

  private func milliseconds(_ keyPath: WritableKeyPath<Settings, Int>, unit: Double) -> Binding<Double> {
    Binding(
      get: { Double(model.settings[keyPath: keyPath]) / unit },
      set: { value in model.update { $0[keyPath: keyPath] = Int((value * unit).rounded()) } }
    )
  }
}
