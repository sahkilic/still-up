import Foundation

struct HttpInfo: Equatable, Sendable {
    var ok: Bool
    var status: Int
    var dev: Bool
}

struct ClassifyEntry: Sendable {
    var command: String = ""
    var comm: String = ""
    var port: Int = 0
    var args: String = ""
    var cwd: String = ""
    var projectFile: Bool = false
    var http: HttpInfo? = nil
}

struct Verdict: Equatable, Sendable {
    var kind: String
    var confidence: String
    var score: Int
    var reason: String
    var canKill: Bool
}

struct Listener: Equatable, Sendable {
    var command: String
    var pid: Int32
    var user: String
    var name: String
    var port: Int
    var address: String
}

struct PsProcess: Equatable, Sendable {
    var pid: Int32
    var ppid: Int32
    var cpu: Double
    var mem: Double
    var rssKb: Int
    var elapsed: String
    var comm: String
    var args: String
}

struct Server: Equatable, Sendable, Identifiable {
    var pid: Int32
    var port: Int
    var command: String
    var args: String
    var cwd: String
    var project: String
    var framework: String
    var title: String
    var cpu: Double
    var rss: String
    var rssKb: Int
    var elapsed: String
    var http: Bool
    var httpDev: Bool
    var kind: String
    var confidence: String
    var reason: String
    var canKill: Bool
    var score: Int

    var id: String { "\(pid):\(port)" }
}

struct ScanResult: Equatable, Sendable {
    var scannedAt: Date
    var servers: [Server]
}

struct BrowserTab: Equatable, Sendable {
    var windowId: Int
    var tabIndex: Int
    var active: Bool
    var url: String
}

struct OpenResult: Equatable, Sendable {
    var focused: Bool
    var browser: String?
    var url: String?
}

enum OpenError: Error, Equatable {
    case unknownBrowser
    case invalidTab
    case invalidPort
}

enum KillError: Error, Equatable {
    case invalid
    case notAllowed
    case refusing
    case failed
}
