import SwiftUI

/// The dropdown shown when the menu bar icon is clicked:
///   Start Work        H:MM
///   Start to Relax     H:MM
///   ---------------
///   Pause Both
///   ---------------
///   Quit
struct MenuContent: View {
    @ObservedObject var manager: StopwatchManager

    var body: some View {
        Button {
            manager.start(.work)
        } label: {
            row(title: "Start Work", elapsed: manager.workElapsed)
        }

        Button {
            manager.start(.relax)
        } label: {
            row(title: "Start to Relax", elapsed: manager.relaxElapsed)
        }

        Divider()

        Button("Pause Both") {
            manager.pauseBoth()
        }

        Divider()

        Button("Quit") {
            manager.quit()
        }
    }

    private func row(title: String, elapsed: TimeInterval) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(formatted(elapsed))
                .foregroundStyle(.secondary)
        }
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
}
