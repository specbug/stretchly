import Foundation

public struct Idea: Equatable, Sendable {
  public let title: String?
  public let text: String
}

public enum IdeaDeck {
  public static func index(for sequence: Int, count: Int, seed: UInt64) -> Int {
    guard count > 0 else { return 0 }
    let round = sequence / count
    let order = permutation(count: count, seed: seed &+ UInt64(truncatingIfNeeded: round))
    return order[sequence % count]
  }

  public static func idea(for plannedBreak: PlannedBreak, seed: UInt64, translator: Translator) -> Idea {
    switch plannedBreak.kind {
    case .mini:
      let keys = translator.keys(under: "miniBreakIdeas")
      guard !keys.isEmpty else { return Idea(title: nil, text: "") }
      let key = keys[index(for: plannedBreak.sequence, count: keys.count, seed: seed)]
      return Idea(title: nil, text: translator.t("miniBreakIdeas.\(key).text"))
    case .long:
      let keys = translator.keys(under: "longBreakIdeas")
      guard !keys.isEmpty else { return Idea(title: nil, text: "") }
      let key = keys[index(for: plannedBreak.sequence, count: keys.count, seed: seed ^ 0x9E37_79B9_7F4A_7C15)]
      return Idea(title: translator.t("longBreakIdeas.\(key).title"), text: translator.t("longBreakIdeas.\(key).text"))
    }
  }

  static func permutation(count: Int, seed: UInt64) -> [Int] {
    var generator = SplitMix64(state: seed)
    var order = Array(0..<count)
    order.shuffle(using: &generator)
    return order
  }
}

struct SplitMix64: RandomNumberGenerator {
  var state: UInt64

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}
