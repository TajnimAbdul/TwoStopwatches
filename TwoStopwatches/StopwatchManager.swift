import AppKit
import Combine
import Foundation

/// The three states the app can be in. Only one stopwatch can ever be
/// running at a time — starting one always pauses the other.
enum StopwatchMode {
    case work
    case relax
    case idle
}

/// Owns the two stopwatches, persists their accumulated time across app
/// restarts, resets them at the start of a new day, and pauses whichever
/// one is running whenever the Mac goes to sleep or the lid is closed.
@MainActor
final class StopwatchManager: NSObject, ObservableObject {

    // MARK: Published state

    @Published private(set) var mode: StopwatchMode = .idle

    /// The pre-rendered menu bar icon. Regenerated every time the mode
    /// changes and once a second while a stopwatch is running. See
    /// `MenuBarIconRenderer` for why this is a bitmap rather than a live
    /// SwiftUI view.
    @Published private(set) var iconImage: NSImage = MenuBarIconRenderer.render(.idle)

    // MARK: Private state

    private var workAccumulated: TimeInterval = 0
    private var relaxAccumulated: TimeInterval = 0
    private var runningSince: Date?

    private var refreshTimer: Timer?
    private var currentDayString: String = ""

    // MARK: Persistence keys

    private let defaults = UserDefaults.standard
    private let workKey = "PulseBar.workAccumulated"
    private let relaxKey = "PulseBar.relaxAccumulated"
    private let dayKey = "PulseBar.lastActiveDay"

    // MARK: Init

    override init() {
        super.init()
        load()
        currentDayString = defaults.string(forKey: dayKey) ?? todayString()
        checkForDayRollover()
        startRefreshTimer()
        registerForSystemNotifications()
        refreshIcon()
    }

    deinit {
        refreshTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Elapsed time (what the UI reads)

    var workElapsed: TimeInterval {
        workAccumulated + liveElapsedIfRunning(in: .work)
    }

    var relaxElapsed: TimeInterval {
        relaxAccumulated + liveElapsedIfRunning(in: .relax)
    }

    private func liveElapsedIfRunning(in target: StopwatchMode) -> TimeInterval {
        guard mode == target, let runningSince else { return 0 }
        return Date().timeIntervalSince(runningSince)
    }

    // MARK: Actions (mirrors the menu: Start Work / Start to Relax / Pause Both / Quit)

    func start(_ target: StopwatchMode) {
        guard target == .work || target == .relax else { return }
        guard mode != target else { return } // already running, nothing to do
        pauseInternal()
        mode = target
        runningSince = Date()
        save()
        refreshIcon()
    }

    func pauseBoth() {
        pauseInternal()
        mode = .idle
        save()
        refreshIcon()
    }

    func quit() {
        pauseInternal()
        save()
        NSApplication.shared.terminate(nil)
    }

    /// Folds the elapsed time of whichever stopwatch is running into its
    /// accumulator and stops the clock, without changing `mode`.
    private func pauseInternal() {
        defer { runningSince = nil }
        guard let runningSince, mode != .idle else { return }
        let elapsed = Date().timeIntervalSince(runningSince)
        switch mode {
        case .work: workAccumulated += elapsed
        case .relax: relaxAccumulated += elapsed
        case .idle: break
        }
    }

    // MARK: Refresh timer

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkForDayRollover()
                self?.refreshIcon()
            }
        }
        // Keep the timer firing even while a menu is open / tracking the mouse.
        if let refreshTimer {
            RunLoop.main.add(refreshTimer, forMode: .common)
        }
    }

    /// Re-rasterises the menu bar icon to match the current mode/elapsed time.
    private func refreshIcon() {
        let content: MenuBarIconContent
        switch mode {
        case .idle:
            content = .idle
        case .work:
            let (hour, minuteProgress) = hourAndMinuteProgress(for: workElapsed)
            content = MenuBarIconContent(mode: .work, hour: hour, minuteProgress: minuteProgress, filled: true)
        case .relax:
            let (hour, minuteProgress) = hourAndMinuteProgress(for: relaxElapsed)
            content = MenuBarIconContent(mode: .relax, hour: hour, minuteProgress: minuteProgress, filled: false)
        }
        iconImage = MenuBarIconRenderer.render(content)
    }

    private func hourAndMinuteProgress(for elapsed: TimeInterval) -> (hour: Int, minuteProgress: Double) {
        let totalSeconds = Int(elapsed)
        return (totalSeconds / 3600, Double(totalSeconds % 3600) / 3600.0)
    }

    // MARK: Day rollover — both stopwatches represent a single 24h window

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }

    private func checkForDayRollover() {
        let today = todayString()
        guard today != currentDayString else { return }
        // A new day has started: fold any running time away and zero both totals.
        runningSince = nil
        mode = .idle
        workAccumulated = 0
        relaxAccumulated = 0
        currentDayString = today
        save()
        refreshIcon()
    }

    // MARK: Persistence

    private func load() {
        workAccumulated = defaults.double(forKey: workKey)
        relaxAccumulated = defaults.double(forKey: relaxKey)
    }

    private func save() {
        defaults.set(workAccumulated, forKey: workKey)
        defaults.set(relaxAccumulated, forKey: relaxKey)
        defaults.set(currentDayString, forKey: dayKey)
    }

    // MARK: Sleep / lid-close / shutdown handling
    //
    // Whenever the system is about to sleep (which also covers the lid
    // closing) or the display sleeps independently, whichever stopwatch is
    // running gets paused and the app falls back to the idle state. It does
    // NOT auto-resume on wake — the user has to pick a mode again.

    private func registerForSystemNotifications() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceCenter.addObserver(
            self,
            selector: #selector(handleSystemPause),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        workspaceCenter.addObserver(
            self,
            selector: #selector(handleSystemPause),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func handleSystemPause() {
        pauseInternal()
        mode = .idle
        save()
        refreshIcon()
    }

    @objc private func handleAppTerminate() {
        pauseInternal()
        save()
    }
}
