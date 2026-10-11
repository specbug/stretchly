import Foundation

public struct Theme: Identifiable, Equatable, Sendable {
  public let id: String
  public let nameKey: String

  public static let all: [Theme] = [
    Theme(id: "#478484", nameKey: "preferences.theme.greenClouds"),
    Theme(id: "#633738", nameKey: "preferences.theme.autumnBeBlessed"),
    Theme(id: "#ffffff", nameKey: "preferences.theme.snowWhite"),
    Theme(id: "#1D1F21", nameKey: "preferences.theme.graphiteCrystal"),
    Theme(id: "#A49898", nameKey: "preferences.theme.coffeeKisses"),
    Theme(id: "#567890", nameKey: "preferences.theme.morningSwim")
  ]

  public static func matching(_ hex: String) -> Theme {
    all.first { $0.id.caseInsensitiveCompare(hex) == .orderedSame } ?? all[0]
  }

  public var usesDarkText: Bool { id.lowercased() == "#ffffff" }

  public var rgb: (red: Double, green: Double, blue: Double) {
    let value = UInt32(id.dropFirst(), radix: 16) ?? 0
    return (
      red: Double((value >> 16) & 0xFF) / 255,
      green: Double((value >> 8) & 0xFF) / 255,
      blue: Double(value & 0xFF) / 255
    )
  }
}

public struct BreakSound: Identifiable, Equatable, Sendable {
  public let id: String
  public let nameKey: String

  public static let all: [BreakSound] = [
    BreakSound(id: "crystal-glass", nameKey: "preferences.theme.crystalGlass"),
    BreakSound(id: "wind-chime", nameKey: "preferences.theme.windChime"),
    BreakSound(id: "tic-toc", nameKey: "preferences.theme.ticToc"),
    BreakSound(id: "reverie", nameKey: "preferences.theme.reverie")
  ]
}
