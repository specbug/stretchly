import StretchlyCore
import SwiftUI

enum StretchlyFont {
  static func light(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
    .custom("NotoSans-Light", size: size, relativeTo: style)
  }

  static func regular(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
    .custom("NotoSans-Regular", size: size, relativeTo: style)
  }
}

extension Color {
  init(hex: UInt32, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: opacity
    )
  }

  init(light: Color, dark: Color) {
    self.init(uiColor: UIColor { traits in
      UIColor(traits.userInterfaceStyle == .dark ? dark : light)
    })
  }

  static let stretchlyText = Color(light: Color(hex: 0x252525), dark: Color(white: 1, opacity: 0.85))
  static let stretchlyBackground = Color(light: Color(hex: 0xEDEDED), dark: Color(hex: 0x2D2D2D))
  static let stretchlyRule = Color(light: Color(hex: 0xDBDBDB), dark: Color(hex: 0x535353))
  static let stretchlyAccent = Color(light: Color(hex: 0x3B99FC), dark: Color(hex: 0x1768E5))
  static let stretchlyControl = Color(light: .white, dark: Color(white: 1, opacity: 0.25))
  static let stretchlyControlBorder = Color(light: Color(white: 0, opacity: 0.2), dark: Color(white: 0, opacity: 0.4))
  static let stretchlySwatchBorder = Color(light: .white, dark: Color(hex: 0x3A3A3A))
  static let stretchlyNavTop = Color(light: Color(hex: 0xEDECED), dark: Color(hex: 0x4B4B4B))
  static let stretchlyNavBottom = Color(light: Color(hex: 0xD2D1D2), dark: Color(hex: 0x3D3D3D))
  static let stretchlySelection = Color(light: Color(hex: 0xB3D7FF), dark: Color(hex: 0x1768E5, opacity: 0.6))
  static let stretchlyHover = Color(hex: 0xFFFF00)
}

extension Theme {
  var color: Color { Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue) }

  var foreground: Color { usesDarkText ? .black : .white }
}

struct Rule: View {
  var body: some View {
    Rectangle()
      .fill(Color.stretchlyRule)
      .frame(height: 1)
      .accessibilityHidden(true)
  }
}

struct Logotype: View {
  var size: CGFloat = 64

  var body: some View {
    HStack(spacing: size * 0.19) {
      Image("logo")
        .resizable()
        .frame(width: size, height: size)
        .accessibilityHidden(true)
      Text(verbatim: "Stretchly")
        .font(StretchlyFont.regular(size * 0.75, relativeTo: .largeTitle))
    }
  }
}

struct StretchlyButtonStyle: ButtonStyle {
  var isPrimary = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(StretchlyFont.regular(16))
      .lineLimit(1)
      .padding(.horizontal, 24)
      .padding(.vertical, 7)
      .frame(minWidth: 200)
      .foregroundStyle(isPrimary ? Color.white : Color.stretchlyText)
      .background {
        RoundedRectangle(cornerRadius: 3)
          .fill(isPrimary
            ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x6CB3FA), Color(hex: 0x067DFF)], startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(Color.stretchlyControl))
      }
      .overlay {
        RoundedRectangle(cornerRadius: 3)
          .strokeBorder(Color.stretchlyControlBorder, lineWidth: 0.5)
      }
      .opacity(configuration.isPressed ? 0.75 : 1)
      .contentShape(Rectangle())
  }
}

struct StretchlyCheckboxStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        ZStack {
          RoundedRectangle(cornerRadius: 3)
            .fill(configuration.isOn ? Color.stretchlyAccent : Color.stretchlyControl)
          RoundedRectangle(cornerRadius: 3)
            .strokeBorder(Color.stretchlyControlBorder, lineWidth: configuration.isOn ? 0 : 0.5)
          if configuration.isOn {
            Image(systemName: "checkmark")
              .font(.system(size: 11, weight: .heavy))
              .foregroundStyle(.white)
          }
        }
        .frame(width: 18, height: 18)
        .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 4 }
        configuration.label
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityRepresentation {
      Toggle(isOn: configuration.$isOn) { configuration.label }
    }
  }
}

struct RadioMark: View {
  let isSelected: Bool

  var body: some View {
    ZStack {
      Circle().fill(isSelected ? Color.stretchlyAccent : Color.stretchlyControl)
      Circle().strokeBorder(Color.stretchlyControlBorder, lineWidth: isSelected ? 0 : 0.5)
      if isSelected {
        Circle().fill(.white).frame(width: 7, height: 7)
      }
    }
    .frame(width: 20, height: 20)
  }
}
