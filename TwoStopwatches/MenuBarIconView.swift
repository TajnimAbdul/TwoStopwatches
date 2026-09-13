import SwiftUI

/// A thin ring that fills clockwise from the top as `progress` goes from
/// 0 to 1 — this is the "radial progress" that represents the minutes
/// (0...59) within the current hour.
private struct RadialMinuteRing: View {
    let progress: Double // 0...1
    var lineWidth: CGFloat = 3.5
    var diameter: CGFloat = 15  // must match the .frame() you apply to this view
    
    /// A round cap extends the visible stroke by ~half the line width past
    /// wherever it's drawn — at both ends. Shrinking the end and advancing
    /// the start by that same angular amount keeps both rounded tips'
    /// outer edges lined up with where accurate flat (.butt) cuts would be:
    /// the start sits exactly at 12 o'clock, the end sits exactly at the
    /// true progress point.
    private var capOvershoot: Double {
        let radius = diameter / 2
        return (lineWidth / 2) / (2 * .pi * radius)
    }

    private var trimStart: Double {
        capOvershoot
    }

    private var trimEnd: Double {
        max(progress - capOvershoot, trimStart + 0.0001)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.35), lineWidth: lineWidth)
            Circle()
                .trim(from: trimStart, to: trimEnd)
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
    static let size = CGSize(width: 22, height: 19)
    private static let overlap: CGFloat = 0

    let mode: StopwatchMode
    let hour: Int
    let minuteProgress: Double
    let filled: Bool

    static let idle = MenuBarIconContent(mode: .idle, hour: 0, minuteProgress: 0, filled: false)

    var body: some View {
        ZStack {
            if mode == .idle {
                Image(systemName: "circle.tophalf.filled.inverse")
                    .resizable().scaledToFit()
                    .foregroundStyle(Color.black)
                    .frame(width: 16, height: 16)
                    .font(.title)
                    .fontWeight(.heavy)
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
