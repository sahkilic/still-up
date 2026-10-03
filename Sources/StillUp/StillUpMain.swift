import AppKit

@main
enum StillUpMain {
    nonisolated(unsafe) private static var delegate: AppDelegate?

    static func main() {
        if !singleInstance() {
            NSApp.terminate(nil)
            return
        }
        let app = NSApplication.shared
        let delegate = MainActor.assumeIsolated { AppDelegate() }
        self.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        app.run()
    }

    private static func singleInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        guard !bundleID.isEmpty else { return true }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier && !$0.isTerminated }
        return others.isEmpty
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = PanelController(preview: CommandLine.arguments.contains("--preview"))

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
