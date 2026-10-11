import StretchlyCore
import SwiftUI

struct RootView: View {
  @Environment(AppModel.self) private var model
  @Environment(Localizer.self) private var localizer
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    @Bindable var model = model
    HomeView()
      .breakPresentation(isEnabled: !model.isShowingPreferences && !model.settings.isFirstRun)
      .sheet(isPresented: $model.isShowingPreferences) {
        PreferencesView()
          .breakPresentation(isEnabled: true)
          .environment(\.layoutDirection, localizer.layoutDirection)
      }
      .fullScreenCover(isPresented: .constant(model.settings.isFirstRun)) {
        WelcomeView()
          .environment(\.layoutDirection, localizer.layoutDirection)
      }
      .environment(\.layoutDirection, localizer.layoutDirection)
      .onChange(of: scenePhase, initial: true) { _, phase in
        switch phase {
        case .active: model.sceneBecameActive()
        case .background: model.sceneEnteredBackground()
        default: break
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
        model.refresh()
      }
  }
}

private struct BreakPresentation: ViewModifier {
  @Environment(AppModel.self) private var model
  @Environment(Localizer.self) private var localizer
  let isEnabled: Bool

  func body(content: Content) -> some View {
    content.fullScreenCover(item: Binding(get: { isEnabled ? model.activeBreak : nil }, set: { _ in })) { plannedBreak in
      BreakView(plannedBreak: plannedBreak)
        .environment(model)
        .environment(localizer)
        .environment(\.layoutDirection, localizer.layoutDirection)
    }
  }
}

extension View {
  func breakPresentation(isEnabled: Bool) -> some View {
    modifier(BreakPresentation(isEnabled: isEnabled))
  }
}
