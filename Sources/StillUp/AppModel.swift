import Foundation

@MainActor
@Observable
final class AppModel {
    private let scans = ScanSerial()

    var result = ScanResult(scannedAt: .distantPast, servers: [])
    var hasScanned = false
    var busy: Set<Int32> = []
    var stoppingAll = false
    var refreshing = false
    var notice = ""
    var noticeUntil = Date.distantPast
    var now = Date()
    var onChange: (@MainActor () -> Void)?

    private var clock: Task<Void, Never>?
    private var poll: Task<Void, Never>?

    var servers: [Server] { result.servers }

    var countText: String {
        if !hasScanned { return "scanning" }
        if servers.isEmpty { return "all clear" }
        return "\(servers.count) up"
    }

    var stampText: String {
        if now < noticeUntil { return notice }
        guard hasScanned, result.scannedAt != .distantPast else { return "" }
        return formatStamp(result.scannedAt, now: now)
    }

    var showStopAll: Bool {
        servers.filter { $0.kind == "dev" }.count >= 2
    }

    var menuLabel: String {
        let count = servers.count
        if count == 0 { return "All clear" }
        return "\(count) leftover \(count == 1 ? "server" : "servers")"
    }

    var tooltip: String {
        let count = servers.count
        if count == 0 { return "Still Up — all clear" }
        return "\(count) leftover \(count == 1 ? "server" : "servers")"
    }

    func startClock() {
        clock?.cancel()
        clock = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                now = Date()
            }
        }
    }

    func startPolling() {
        poll?.cancel()
        poll = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                guard !Task.isCancelled else { return }
                await refresh()
            }
        }
    }

    func stopPolling() {
        poll?.cancel()
        poll = nil
    }

    func refresh() async {
        refreshing = true
        defer {
            refreshing = false
            onChange?()
        }
        if let next = await scans.run() {
            result = next
            hasScanned = true
        }
    }

    func open(_ server: Server, forceNew: Bool) async {
        guard !busy.contains(server.pid) else { return }
        guard result.servers.contains(where: { $0.port == server.port }) else { return }
        do {
            let opened = try await BrowserOpen.open(port: server.port, forceNew: forceNew)
            if opened.focused, let browser = opened.browser {
                showNotice("showing in \(browser)")
            } else {
                showNotice("opened a tab")
            }
        } catch {
            showNotice("couldn't open")
        }
    }

    func stop(_ pid: Int32) async {
        guard !busy.contains(pid) else { return }
        busy.insert(pid)
        defer { busy.remove(pid) }
        let allowed = Set(result.servers.filter(\.canKill).map(\.pid))
        try? await Scanner.stopProcess(pid: pid, allowed: allowed)
        await refresh()
    }

    func stopAll() async {
        stoppingAll = true
        defer { stoppingAll = false }
        let pids = result.servers.filter { $0.canKill && $0.kind == "dev" }.map(\.pid)
        let allowed = Set(pids)
        for pid in pids {
            try? await Scanner.stopProcess(pid: pid, allowed: allowed)
        }
        await refresh()
    }

    private func showNotice(_ text: String) {
        notice = text
        noticeUntil = Date().addingTimeInterval(2.5)
        now = Date()
    }
}

private actor ScanSerial {
    private var epoch = 0

    func run() async -> ScanResult? {
        epoch += 1
        let mine = epoch
        let result = try? await Scanner.scan()
        guard mine == epoch else { return nil }
        return result
    }
}
