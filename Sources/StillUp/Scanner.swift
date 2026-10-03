import Darwin
import Foundation

private let projectMarkers = [
    "package.json",
    "pnpm-workspace.yaml",
    "pyproject.toml",
    "manage.py",
    "Gemfile",
    "Cargo.toml",
    "go.mod",
    "composer.json",
    "deno.json",
    "bun.lockb",
    "next.config.js",
    "next.config.mjs",
    "vite.config.ts",
    "vite.config.js",
    "astro.config.mjs",
]

private actor ProjectFiles {
    private var cache: [String: Bool] = [:]

    func contains(_ cwd: String) -> Bool {
        if let cached = cache[cwd] { return cached }
        let value = Self.hasProjectFile(cwd)
        cache[cwd] = value
        return value
    }

    private static func hasProjectFile(_ cwd: String) -> Bool {
        if cwd.isEmpty || cwd == "/" || cwd.hasPrefix("/System") || cwd.hasPrefix("/usr") {
            return false
        }
        let folder = URL(fileURLWithPath: cwd, isDirectory: true)
        return projectMarkers.contains { marker in
            FileManager.default.fileExists(atPath: folder.appendingPathComponent(marker).path)
        }
    }
}

enum Scanner {
    static func scan() async throws -> ScanResult {
        let lsofOut = try await Shell.run("lsof", ["-nP", "-iTCP", "-sTCP:LISTEN"])
        let user = ProcessInfo.processInfo.environment["USER"]
        let selfPid = ProcessInfo.processInfo.processIdentifier
        var seen = Set<String>()
        let listeners = parseLsof(lsofOut).filter { listener in
            if let user, listener.user != user { return false }
            if listener.pid == selfPid { return false }
            let key = "\(listener.pid):\(listener.port)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        if listeners.isEmpty {
            return ScanResult(scannedAt: Date(), servers: [])
        }

        let pidList = Array(Set(listeners.map(\.pid))).map(String.init).joined(separator: ",")
        async let psTask = Shell.run("ps", ["-ww", "-p", pidList, "-o", "pid=,ppid=,pcpu=,pmem=,rss=,etime=,command="])
        async let cwdTask = cwdOutput(pidList)
        let processes = parsePs(try await psTask)
        let cwds = parseCwd(await cwdTask)
        let projects = ProjectFiles()

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 0.28
        config.timeoutIntervalForResource = 0.45
        config.waitsForConnectivity = false
        let session = URLSession(configuration: config)
        defer { session.finishTasksAndInvalidate() }

        var servers: [Server] = []
        await withTaskGroup(of: Server?.self) { group in
            for listener in listeners {
                group.addTask {
                    await enrich(listener, processes: processes, cwds: cwds, projects: projects, session: session)
                }
            }
            for await server in group {
                if let server { servers.append(server) }
            }
        }

        servers.sort { lhs, rhs in
            if lhs.port != rhs.port { return lhs.port < rhs.port }
            return lhs.pid < rhs.pid
        }
        return ScanResult(scannedAt: Date(), servers: servers)
    }

    static func stopProcess(pid: Int32, allowed: Set<Int32>) async throws {
        guard pid > 1 else { throw KillError.invalid }
        guard allowed.contains(pid) else { throw KillError.notAllowed }
        let selfPid = ProcessInfo.processInfo.processIdentifier
        if pid == selfPid || pid == getppid() { throw KillError.refusing }

        if Darwin.kill(pid, SIGTERM) != 0 {
            if errno == ESRCH { return }
            throw KillError.failed
        }

        try await Task.sleep(nanoseconds: 700_000_000)
        if Darwin.kill(pid, 0) == 0 {
            if Darwin.kill(pid, SIGKILL) != 0, errno != ESRCH {
                throw KillError.failed
            }
        } else if errno != ESRCH {
            throw KillError.failed
        }
    }

    private static func cwdOutput(_ pidList: String) async -> String {
        (try? await Shell.run("lsof", ["-a", "-d", "cwd", "-p", pidList, "-Fn"])) ?? ""
    }

    private static func enrich(
        _ listener: Listener,
        processes: [Int32: PsProcess],
        cwds: [Int32: String],
        projects: ProjectFiles,
        session: URLSession
    ) async -> Server? {
        let proc = processes[listener.pid]
        let cwd = cwds[listener.pid] ?? ""
        let projectFile = await projects.contains(cwd)
        let draft = ClassifyEntry(
            command: listener.command,
            comm: proc?.comm.isEmpty == false ? proc!.comm : listener.command,
            port: listener.port,
            args: proc?.args ?? "",
            cwd: cwd,
            projectFile: projectFile
        )
        let verdict = classify(draft)
        if verdict.confidence == "hide" { return nil }

        var httpInfo: HttpInfo?
        if verdict.canKill || verdict.kind == "maybe" {
            httpInfo = await probeHttp(port: listener.port, session: session)
        }
        var probed = draft
        probed.http = httpInfo
        let finalVerdict = classify(probed)
        if finalVerdict.confidence == "hide" { return nil }

        let project = projectName(cwd)
        let framework = inferFramework(draft)
        let comm = draft.comm
        return Server(
            pid: listener.pid,
            port: listener.port,
            command: comm.isEmpty ? listener.command : comm,
            args: draft.args,
            cwd: cwd,
            project: project,
            framework: framework,
            title: project.isEmpty ? framework : "\(framework) · \(project)",
            cpu: proc?.cpu ?? 0,
            rss: formatRss(proc?.rssKb ?? 0),
            rssKb: proc?.rssKb ?? 0,
            elapsed: formatElapsed(proc?.elapsed ?? ""),
            http: httpInfo?.ok == true,
            httpDev: httpInfo?.dev == true,
            kind: finalVerdict.kind,
            confidence: finalVerdict.confidence,
            reason: finalVerdict.reason,
            canKill: finalVerdict.canKill,
            score: finalVerdict.score
        )
    }

    private static func probeHttp(port: Int, session: URLSession) async -> HttpInfo? {
        guard let url = URL(string: "http://127.0.0.1:\(port)/") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 0.28)
        request.setValue("text/html,*/*", forHTTPHeaderField: "Accept")
        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            var body = Data()
            body.reserveCapacity(2048)
            for try await byte in bytes {
                body.append(byte)
                if body.count >= 2048 { break }
            }
            let headers = http.allHeaderFields.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            let text = String(data: body, encoding: .utf8) ?? ""
            return HttpInfo(
                ok: http.statusCode > 0 && http.statusCode < 500,
                status: http.statusCode,
                dev: detectDevHttp(headers, text)
            )
        } catch {
            return nil
        }
    }
}
