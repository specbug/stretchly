import SwiftUI

struct ProgressBar: View {
  let start: Date
  let end: Date
  let width: CGFloat

  var body: some View {
    let total = max(end.timeIntervalSince(start), 0.001)
    let cadence = max(1.0 / 30, total / Double(max(width, 1) * 2))
    TimelineView(.animation(minimumInterval: cadence)) { context in
      let fraction = min(1, max(0, end.timeIntervalSince(context.date) / total))
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 3)
          .fill(Color(hex: 0xCECECE))
          .frame(width: width * fraction)
        RoundedRectangle(cornerRadius: 3)
          .strokeBorder(Color(hex: 0xBCBCBC), lineWidth: 0.5)
      }
      .frame(width: width, height: 6)
    }
    .accessibilityHidden(true)
  }
}
