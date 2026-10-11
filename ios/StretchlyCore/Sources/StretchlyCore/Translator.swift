import Foundation

public indirect enum TranslationNode: Decodable, Equatable, Sendable {
  case text(String)
  case group([String: TranslationNode])
  case unsupported

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let text = try? container.decode(String.self) {
      self = .text(text)
    } else if let group = try? container.decode([String: TranslationNode].self) {
      self = .group(group)
    } else {
      self = .unsupported
    }
  }

  func node(at path: [Substring]) -> TranslationNode? {
    guard let head = path.first else { return self }
    guard case .group(let children) = self, let child = children[String(head)] else { return nil }
    return child.node(at: Array(path.dropFirst()))
  }
}

public struct Translator: Sendable {
  public static let fallbackLanguage = "en"
  public static let rightToLeftLanguages: Set<String> = ["ajp", "arz", "fa", "he", "yi"]

  public let language: String
  private let primary: TranslationNode
  private let fallback: TranslationNode

  public init(language: String, primary: TranslationNode, fallback: TranslationNode) {
    self.language = language
    self.primary = primary
    self.fallback = fallback
  }

  public init(language: String, primaryJSON: Data?, fallbackJSON: Data) throws {
    let decoder = JSONDecoder()
    let fallback = try decoder.decode(TranslationNode.self, from: fallbackJSON)
    let primary = try primaryJSON.map { try decoder.decode(TranslationNode.self, from: $0) } ?? fallback
    self.init(language: language, primary: primary, fallback: fallback)
  }

  public var isRightToLeft: Bool { Translator.rightToLeftLanguages.contains(language) }

  public func t(_ key: String, _ values: [String: String] = [:]) -> String {
    let text = lookup(key, in: primary) ?? lookup(key, in: fallback) ?? key
    return interpolate(text, values)
  }

  public func t(_ key: String, count: Double, _ values: [String: String] = [:]) -> String {
    var values = values
    values["count"] = values["count"] ?? Translator.format(count)
    let primaryCategory = PluralRules.category(for: language, count: count).rawValue
    let fallbackCategory = PluralRules.category(for: Translator.fallbackLanguage, count: count).rawValue
    let text = lookup("\(key)_\(primaryCategory)", in: primary)
      ?? lookup("\(key)_other", in: primary)
      ?? lookup(key, in: primary)
      ?? lookup("\(key)_\(fallbackCategory)", in: fallback)
      ?? lookup("\(key)_other", in: fallback)
      ?? lookup(key, in: fallback)
      ?? key
    return interpolate(text, values)
  }

  public func keys(under key: String) -> [String] {
    guard case .group(let children)? = fallback.node(at: key.split(separator: ".")) else { return [] }
    return children.keys.sorted()
  }

  public func duration(_ seconds: TimeInterval, units: [DurationUnit]) -> String {
    DurationUnit.components(of: seconds, units: units)
      .map { t("utils.\($0.unit.rawValue)", count: Double($0.value)) }
      .joined(separator: " ")
  }

  public func unitValue(seconds: TimeInterval) -> String {
    if seconds < 60 {
      return t("utils.seconds", count: seconds.rounded())
    }
    let minutes = (seconds / 6).rounded() / 10
    return t("utils.minutes", count: minutes)
  }

  public static func format(_ count: Double) -> String {
    if count == count.rounded() {
      return String(Int(count))
    }
    return String(format: "%.1f", count)
  }

  private func lookup(_ key: String, in root: TranslationNode) -> String? {
    guard case .text(let text)? = root.node(at: key.split(separator: ".")), !text.isEmpty else { return nil }
    return text
  }

  private func interpolate(_ text: String, _ values: [String: String]) -> String {
    guard text.contains("{{") else { return text }
    var result = text
    for (name, value) in values {
      result = result.replacingOccurrences(of: "{{\(name)}}", with: value)
    }
    return result
  }
}

public enum DurationUnit: String, CaseIterable, Sendable {
  case hours
  case minutes
  case seconds

  public var seconds: Int {
    switch self {
    case .hours: return 3600
    case .minutes: return 60
    case .seconds: return 1
    }
  }

  public static func components(of seconds: TimeInterval, units: [DurationUnit]) -> [(unit: DurationUnit, value: Int)] {
    let ordered = units.sorted { $0.seconds > $1.seconds }
    guard let smallest = ordered.last else { return [] }
    var remaining = Int((max(0, seconds) / Double(smallest.seconds)).rounded()) * smallest.seconds
    var parts: [(unit: DurationUnit, value: Int)] = []
    for unit in ordered {
      let value = remaining / unit.seconds
      remaining -= value * unit.seconds
      if value > 0 {
        parts.append((unit: unit, value: value))
      }
    }
    return parts.isEmpty ? [(unit: smallest, value: 0)] : parts
  }
}
