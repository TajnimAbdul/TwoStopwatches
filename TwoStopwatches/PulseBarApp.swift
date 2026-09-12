import AppKit
import SwiftUI

@main
struct PulseBarApp: App {
    @StateObject private var manager = StopwatchManager()

    init() {
        // Menu-bar-only app: no Dock icon, no Cmd-Tab entry.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(manager: manager)
        } label: {
            Image(nsImage: manager.iconImage)
        }
        .menuBarExtraStyle(.menu)
    }
}
