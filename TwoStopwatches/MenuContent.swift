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
            Label {
              row(title: "Work", elapsed: manager.workElapsed)
            } icon: {
              Image(systemName: "star.fill")
            }
        }

        Button {
            manager.start(.relax)
        } label: {
            Label {
                row(title: "Relax", elapsed: manager.relaxElapsed)
            } icon: {
                Image(systemName: "heart.fill")
            }
        }
        Divider()

        Button {
            manager.pauseBoth()
        } label: {
            Label {
              Text("Pause Both")
            } icon: {
              Image(systemName: "pause.fill")
            }
        }

        Divider()
        
        Button {
            manager.quit()
        } label: {
          Label {
            Text("Quit")
          } icon: {
            Image(systemName: "x.circle")
          }
      }
    }

    private func row(title: String, elapsed: TimeInterval) -> some View {
        var line = AttributedString(title + "   ")

        var time = AttributedString(formatted(elapsed))
        time.foregroundColor = .secondary

        line += time
        return Text(line)
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
}
