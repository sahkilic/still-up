import Foundation

enum ShellError: Error {
    case failed(String)
}

private final class ByteBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    private var finished = false

    func append(_ chunk: Data) {
        lock.lock()
        defer { lock.unlock() }
        if data.count < 8 * 1024 * 1024 {
            data.append(chunk)
        }
    }

    func take() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }

    func finish(_ group: DispatchGroup) {
        lock.lock()
        let first = !finished
        finished = true
        lock.unlock()
        if first { group.leave() }
    }
}

enum Shell {
    static func run(_ name: String, _ arguments: [String], timeout: TimeInterval = 4) async throws -> String {
        let resolved = resolve(name)
        return try await Task.detached(priority: .userInitiated) {
            try runSync(resolved, arguments, timeout: timeout, name: name)
        }.value
    }

    private static func resolve(_ name: String) -> String {
        for path in ["/usr/sbin/\(name)", "/usr/bin/\(name)", "/bin/\(name)"] {
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        return "/usr/bin/\(name)"
    }

    private static func runSync(_ path: String, _ arguments: [String], timeout: TimeInterval, name: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        let handle = pipe.fileHandleForReading
        let buffer = ByteBuffer()
        let group = DispatchGroup()
        group.enter()
        handle.readabilityHandler = { file in
            let chunk = file.availableData
            if chunk.isEmpty {
                file.readabilityHandler = nil
                buffer.finish(group)
                return
            }
            buffer.append(chunk)
        }

        do {
            try process.run()
        } catch {
            handle.readabilityHandler = nil
            buffer.finish(group)
            throw error
        }

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.02)
        }
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        _ = group.wait(timeout: .now() + 1)
        handle.readabilityHandler = nil
        buffer.finish(group)

        let stdout = String(decoding: buffer.take(), as: UTF8.self)
        if stdout.isEmpty && process.terminationStatus != 0 {
            throw ShellError.failed(name)
        }
        return stdout
    }
}
