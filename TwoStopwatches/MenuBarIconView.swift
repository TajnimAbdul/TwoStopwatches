import SwiftUI

/// A thin ring that fills clockwise from the top as `progress` goes from
/// 0 to 1 — this is the "radial progress" that represents the minutes
/// (0...59) within the current hour.
private struct RadialMinuteRing: View {
    let progress: Double // 0...1
    var lineWidth: CGFloat = 3.4

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.35), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(progress, 0.0001))
                .stroke(Color.black, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

/// The hour, drawn using the numbered SF Symbol circles (`0.circle` ...
/// `23.circle`, or their `.fill` variants). Filled = Work, unfilled = Relax.
private struct HourGlyph: View {
    let hour: Int
    let filled: Bool

    var body: some View {
      (hour == 0 ? Image(systemName: "0.circle\(filled ? ".fill" : "").ar") : Image(systemName: "\(hour).circle\(filled ? ".fill" : "")"))
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.black)
            .opacity(0.55)
    }
}

/// Pure, state-free description of the composite menu bar icon: the hour
/// glyph and the minute ring overlap slightly, Venn-diagram / Mastercard
/// logo style. When idle it shows a neutral filled/unfilled circle pair
/// instead. Drawn in plain black — `MenuBarIconRenderer` rasterises this
/// into a *template* `NSImage`, so macOS repaints it white/black to match
/// the current menu bar appearance automatically.
///
/// This is a value type with no dependency on `StopwatchManager` on
/// purpose: it needs to be renderable off-screen into a bitmap, because
/// `MenuBarExtra`'s label does not reliably composite overlapping SwiftUI
/// views live (overlapping content was silently being clipped/dropped).
struct MenuBarIconContent: View {
    static let size = CGSize(width: 31, height: 18)
    private static let overlap: CGFloat = 0

    let mode: StopwatchMode
    let hour: Int
    let minuteProgress: Double
    let filled: Bool

    static let idle = MenuBarIconContent(mode: .idle, hour: 0, minuteProgress: 0, filled: false)

    var body: some View {
        ZStack {
            if mode == .idle {
                Image(systemName: "circle.fill")
                    .resizable().scaledToFit()
                    .foregroundStyle(Color.black)
                    .frame(width: 15, height: 15)
                    .offset(x: -Self.overlap)
//                Image(systemName: "circle")
//                    .resizable().scaledToFit()
//                    .foregroundStyle(Color.black)
//                    .frame(width: 15, height: 15)
//                    .offset(x: Self.overlap)
            } else {
                HourGlyph(hour: hour, filled: filled)
                    .frame(width: 15, height: 15)
                    .offset(x: -Self.overlap)
                RadialMinuteRing(progress: minuteProgress)
                    .frame(width: 15, height: 15)
                    .offset(x: Self.overlap)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }
}
