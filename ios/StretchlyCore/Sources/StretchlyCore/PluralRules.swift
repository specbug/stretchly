import Foundation

public enum PluralCategory: String, Sendable {
  case zero, one, two, few, many, other
}

public enum PluralRules {
  public static func category(for language: String, count: Double) -> PluralCategory {
    let operands = Operands(count)
    let n = operands.n
    let i = operands.i
    let v = operands.v
    let f = operands.f
    let isInteger = v == 0

    switch language {
    case "pt-BR":
      if (0...1).contains(i) { return .one }
      return manyForMillions(operands) ?? .other
    case "pt":
      if i == 1 && isInteger { return .one }
      return manyForMillions(operands) ?? .other
    case "fr":
      if (0...1).contains(i) { return .one }
      return manyForMillions(operands) ?? .other
    case "es", "it", "ca":
      if n == 1 && (language == "es" || isInteger) { return .one }
      return manyForMillions(operands) ?? .other
    case "ro":
      if i == 1 && isInteger { return .one }
      if !isInteger || n == 0 || (n != 1 && (1...19).contains(i % 100)) { return .few }
      return .other
    case "he":
      if (i == 1 && isInteger) || (i == 0 && !isInteger) { return .one }
      if i == 2 && isInteger { return .two }
      return .other
    case "pl":
      guard isInteger else { return .other }
      if i == 1 { return .one }
      if (2...4).contains(i % 10) && !(12...14).contains(i % 100) { return .few }
      return .many
    case "ru", "uk", "be":
      guard isInteger else { return .other }
      if i % 10 == 1 && i % 100 != 11 { return .one }
      if (2...4).contains(i % 10) && !(12...14).contains(i % 100) { return .few }
      return .many
    case "lt":
      if !isInteger { return .many }
      if i % 10 == 1 && !(11...19).contains(i % 100) { return .one }
      if (2...9).contains(i % 10) && !(11...19).contains(i % 100) { return .few }
      return .other
    case "lv":
      if isInteger && (i % 10 == 0 || (11...19).contains(i % 100)) { return .zero }
      if isInteger && i % 10 == 1 && i % 100 != 11 { return .one }
      if !isInteger && f % 10 == 1 && f % 100 != 11 { return .one }
      return .other
    case "cs", "sk":
      if !isInteger { return .many }
      if i == 1 { return .one }
      if (2...4).contains(i) { return .few }
      return .other
    case "sl":
      if !isInteger { return .few }
      if i % 100 == 1 { return .one }
      if i % 100 == 2 { return .two }
      if (3...4).contains(i % 100) { return .few }
      return .other
    case "sr":
      if (isInteger && i % 10 == 1 && i % 100 != 11) || (!isInteger && f % 10 == 1 && f % 100 != 11) { return .one }
      if (isInteger && (2...4).contains(i % 10) && !(12...14).contains(i % 100)) ||
        (!isInteger && (2...4).contains(f % 10) && !(12...14).contains(f % 100)) { return .few }
      return .other
    case "mk":
      if (isInteger && i % 10 == 1 && i % 100 != 11) || (!isInteger && f % 10 == 1 && f % 100 != 11) { return .one }
      return .other
    case "ajp", "arz", "ar":
      guard isInteger else { return .other }
      if i == 0 { return .zero }
      if i == 1 { return .one }
      if i == 2 { return .two }
      if (3...10).contains(i % 100) { return .few }
      if (11...99).contains(i % 100) { return .many }
      return .other
    case "cy":
      guard isInteger else { return .other }
      switch i {
      case 0: return .zero
      case 1: return .one
      case 2: return .two
      case 3: return .few
      case 6: return .many
      default: return .other
      }
    case "fa", "hi", "bn", "gu":
      return i == 0 || n == 1 ? .one : .other
    case "pu":
      return (0...1).contains(i) && isInteger ? .one : .other
    case "si":
      return n == 0 || n == 1 || (i == 0 && f == 1) ? .one : .other
    case "fil":
      let excluded: Set<Int> = [4, 6, 9]
      if isInteger && ((1...3).contains(i) || !excluded.contains(i % 10)) { return .one }
      if !isInteger && !excluded.contains(f % 10) { return .one }
      return .other
    case "da":
      return n == 1 || (!isInteger && (0...1).contains(i)) ? .one : .other
    case "ja", "ko", "zh-CN", "zh-TW", "th", "vi", "id":
      return .other
    case "en", "de", "nl", "sv", "nb-NO", "et", "fi", "gl", "yi":
      return i == 1 && isInteger ? .one : .other
    default:
      return n == 1 ? .one : .other
    }
  }

  private static func manyForMillions(_ operands: Operands) -> PluralCategory? {
    operands.v == 0 && operands.i != 0 && operands.i % 1_000_000 == 0 ? .many : nil
  }

  private struct Operands {
    let n: Double
    let i: Int
    let v: Int
    let f: Int

    init(_ value: Double) {
      n = abs(value)
      i = Int(n)
      var fraction = n - Double(i)
      var digits = 0
      var fractionDigits = 0
      while fraction > 0.0000001 && digits < 3 {
        fraction *= 10
        let digit = Int(fraction + 0.0000001)
        fractionDigits = fractionDigits * 10 + digit
        fraction -= Double(digit)
        digits += 1
      }
      v = digits
      f = fractionDigits
    }
  }
}
