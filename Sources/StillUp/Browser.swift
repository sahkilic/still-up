import AppKit
import Foundation

struct KnownBrowser: Sendable {
    var name: String
    var kind: String
}

let browsers: [KnownBrowser] = [
    KnownBrowser(name: "Google Chrome", kind: "chromium"),
    KnownBrowser(name: "Google Chrome Canary", kind: "chromium"),
    KnownBrowser(name: "Arc", kind: "chromium"),
    KnownBrowser(name: "Dia", kind: "chromium"),
    KnownBrowser(name: "Brave Browser", kind: "chromium"),
    KnownBrowser(name: "Microsoft Edge", kind: "chromium"),
    KnownBrowser(name: "Vivaldi", kind: "chromium"),
    KnownBrowser(name: "Opera", kind: "chromium"),
    KnownBrowser(name: "Chromium", kind: "chromium"),
    KnownBrowser(name: "Safari", kind: "safari"),
    KnownBrowser(name: "Safari Technology Preview", kind: "safari"),
    KnownBrowser(name: "Orion", kind: "safari"),
]

func urlMatchesPort(_ urlString: String, _ port: Int) -> Bool {
    guard let parsed = URL(string: urlString), let scheme = parsed.scheme?.lowercased() else { return false }
    if scheme != "http" && scheme != "https" { return false }
    let explicit: Int
    if let value = parsed.port {
        explicit = value
    } else {
        explicit = scheme == "https" ? 443 : 80
    }
    if explicit != port { return false }
    let host = (parsed.host ?? "").lowercased().replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
    return host == "localhost" || host.hasSuffix(".localhost") || host == "127.0.0.1" || host == "::1" || host == "0.0.0.0"
}

func parseTabList(_ stdout: String) -> [BrowserTab] {
    var tabs: [BrowserTab] = []
    for lineSub in stdout.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = String(lineSub)
        if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
        let parts = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 4, let windowId = Int(parts[0]), let index = Int(parts[1]), index >= 1 else { continue }
        let url = parts.dropFirst(3).joined(separator: "\t")
        tabs.append(BrowserTab(windowId: windowId, tabIndex: index, active: parts[2] == "1", url: url))
    }
    return tabs
}

func chooseTab(_ tabs: [BrowserTab], _ port: Int) -> BrowserTab? {
    let matches = tabs.filter { urlMatchesPort($0.url, port) }
    guard let first = matches.first else { return nil }
    return matches.first { $0.windowId == first.windowId && $0.active } ?? first
}

func listScript(_ name: String) throws -> String {
    let browser = try knownBrowser(name)
    let activeLine = browser.kind == "safari"
        ? "set activeIndex to index of current tab of w"
        : "set activeIndex to active tab index of w"
    return """
        set out to ""
        set col to ASCII character 9
        tell application "\(browser.name)"
          repeat with w in windows
            try
              set activeIndex to 0
              \(activeLine)
              set ti to 0
              repeat with t in tabs of w
                set ti to ti + 1
                try
                  set flag to "0"
                  if ti is activeIndex then set flag to "1"
                  set out to out & (id of w as text) & col & (ti as text) & col & flag & col & (URL of t) & linefeed
                end try
              end repeat
            end try
          end repeat
        end tell
        return out
    """
}

func activateScript(_ name: String, _ windowId: Int, _ tabIndex: Int) throws -> String {
    let browser = try knownBrowser(name)
    if windowId == 0 || tabIndex < 1 { throw OpenError.invalidTab }
    if browser.kind == "safari" {
        return """
            tell application "\(browser.name)"
              set w to first window whose id is \(windowId)
              set current tab of w to tab \(tabIndex) of w
              set index of w to 1
              activate
            end tell
        """
    }
    return """
        tell application "\(browser.name)"
          set w to first window whose id is \(windowId)
          set active tab index of w to \(tabIndex)
          set index of w to 1
          try
            set miniaturized of w to false
          end try
          activate
        end tell
    """
}

func knownBrowser(_ name: String) throws -> KnownBrowser {
    guard let browser = browsers.first(where: { $0.name == name }) else {
        throw OpenError.unknownBrowser
    }
    return browser
}

enum BrowserOpen {
    static func open(port: Int, forceNew: Bool) async throws -> OpenResult {
        guard port >= 1 && port <= 65535 else { throw OpenError.invalidPort }
        if !forceNew, let focused = await focusExisting(port) {
            return focused
        }
        let urlString = "http://localhost:\(port)"
        guard let url = URL(string: urlString) else { throw OpenError.invalidPort }
        let opened = await MainActor.run {
            NSWorkspace.shared.open(url)
        }
        if !opened { throw OpenError.invalidPort }
        return OpenResult(focused: false, browser: nil, url: urlString)
    }

    private static func focusExisting(_ port: Int) async -> OpenResult? {
        let running = await runningBrowsers()
        for browser in running {
            let listed: [BrowserTab]
            do {
                let source = try listScript(browser.name)
                let stdout = try await Shell.run("osascript", ["-e", source], timeout: 20)
                listed = parseTabList(stdout)
            } catch {
                continue
            }
            guard let chosen = chooseTab(listed, port) else { continue }
            do {
                let source = try activateScript(browser.name, chosen.windowId, chosen.tabIndex)
                _ = try await Shell.run("osascript", ["-e", source], timeout: 20)
                return OpenResult(focused: true, browser: browser.name, url: nil)
            } catch {
                continue
            }
        }
        return nil
    }

    private static func runningBrowsers() async -> [KnownBrowser] {
        var running: [KnownBrowser] = []
        for browser in browsers {
            if await isRunning(browser.name) {
                running.append(browser)
            }
        }
        let front = await frontmostApp()
        running.sort { lhs, rhs in
            if lhs.name == front { return true }
            if rhs.name == front { return false }
            return false
        }
        return running
    }

    private static func isRunning(_ name: String) async -> Bool {
        (try? await Shell.run("pgrep", ["-x", name], timeout: 1)) != nil
    }

    private static func frontmostApp() async -> String {
        guard let front = try? await Shell.run("lsappinfo", ["front"], timeout: 1) else { return "" }
        guard let info = try? await Shell.run("lsappinfo", ["info", "-only", "name", front.trimmingCharacters(in: .whitespacesAndNewlines)], timeout: 1) else {
            return ""
        }
        guard let match = firstGroups(#""LSDisplayName"="([^"]+)""#, in: info), match.count > 1 else { return "" }
        return match[1]
    }
}
