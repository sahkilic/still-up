import Foundation

private let lsofPattern = #"^(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$"#
private let listenPattern = #":(\d+)\s+\(LISTEN\)"#
private let psPattern = #"^\s*(\d+)\s+(\d+)\s+([\d.]+)\s+([\d.]+)\s+(\d+)\s+(\S+)\s+(.*)$"#
private let elapsedPattern = #"^(?:(?:(\d+)-)?(\d+):)?(\d+):(\d+)$"#

func parseLsof(_ stdout: String) -> [Listener] {
    var listeners: [Listener] = []
    let lines = stdout.split(separator: "\n", omittingEmptySubsequences: false).dropFirst()
    for lineSub in lines {
        let line = String(lineSub)
        if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
        guard let match = firstGroups(lsofPattern, in: line), match.count >= 10 else { continue }
        let name = match[9]
        guard let listen = firstGroups(listenPattern, in: name), let port = Int(listen.count > 1 ? listen[1] : "") else { continue }
        let address: String
        if name.hasPrefix("["), let end = name.lastIndex(of: "]") {
            address = String(name[...end])
        } else {
            address = name.split(separator: ":", maxSplits: 1).first.map(String.init) ?? name
        }
        listeners.append(
            Listener(
                command: match[1],
                pid: Int32(match[2]) ?? 0,
                user: match[3],
                name: name,
                port: port,
                address: address
            )
        )
    }
    return listeners
}

func parsePs(_ stdout: String) -> [Int32: PsProcess] {
    var processes: [Int32: PsProcess] = [:]
    for lineSub in stdout.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = String(lineSub)
        if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
        guard let match = firstGroups(psPattern, in: line), match.count >= 8 else { continue }
        let pid = Int32(match[1]) ?? 0
        let args = match[7].trimmingCharacters(in: .whitespaces)
        let first = args.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? ""
        let comm = first.split(separator: "/").last.map(String.init) ?? ""
        processes[pid] = PsProcess(
            pid: pid,
            ppid: Int32(match[2]) ?? 0,
            cpu: Double(match[3]) ?? 0,
            mem: Double(match[4]) ?? 0,
            rssKb: Int(match[5]) ?? 0,
            elapsed: match[6],
            comm: comm,
            args: args
        )
    }
    return processes
}

func parseCwd(_ stdout: String) -> [Int32: String] {
    var cwds: [Int32: String] = [:]
    var pid: Int32?
    for lineSub in stdout.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = String(lineSub)
        if line.hasPrefix("p") {
            pid = Int32(line.dropFirst())
        } else if line.hasPrefix("n"), let pid {
            cwds[pid] = String(line.dropFirst())
        }
    }
    return cwds
}

func formatElapsed(_ etime: String) -> String {
    if etime.isEmpty { return "" }
    guard let match = firstGroups(elapsedPattern, in: etime), match.count >= 5 else { return etime }
    let days = Int(match[1]) ?? 0
    let hours = Int(match[2]) ?? 0
    let minutes = Int(match[3]) ?? 0
    let seconds = Int(match[4]) ?? 0
    if days > 0 { return hours > 0 ? "\(days)d \(hours)h" : "\(days)d" }
    if hours > 0 { return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h" }
    if minutes > 0 { return "\(minutes)m" }
    return "\(seconds)s"
}

func formatRss(_ rssKb: Int) -> String {
    if rssKb <= 0 { return "0 MB" }
    if rssKb >= 1024 * 1024 {
        return String(format: "%.1f GB", Double(rssKb) / 1024 / 1024)
    }
    if rssKb >= 1024 {
        return "\(Int((Double(rssKb) / 1024).rounded())) MB"
    }
    return "\(rssKb) KB"
}

func formatCpu(_ cpu: Double) -> String {
    if cpu >= 10 {
        return "\(Int(cpu.rounded()))%"
    }
    return String(format: "%.1f%%", cpu)
}

func formatStamp(_ scannedAt: Date, now: Date = Date()) -> String {
    let seconds = max(0, Int((now.timeIntervalSince(scannedAt)).rounded()))
    if seconds < 2 { return "just now" }
    if seconds < 60 { return "\(seconds)s ago" }
    return "\(Int((Double(seconds) / 60).rounded()))m ago"
}

func densityLevel(for count: Int) -> Int {
    if count <= 1 { return 1 }
    if count == 2 { return 2 }
    if count <= 4 { return 3 }
    return 4
}
