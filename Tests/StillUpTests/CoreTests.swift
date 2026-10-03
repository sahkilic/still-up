import AppKit
import SwiftUI
import Testing
@testable import StillUp

@Test(arguments: [
    ClassifyEntry(command: "ControlCe", comm: "Control Center", port: 5000, args: "/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter"),
    ClassifyEntry(command: "ControlCe", comm: "Control Center", port: 7000, args: "Control Center"),
    ClassifyEntry(command: "rapportd", comm: "rapportd", port: 51753, args: "/usr/libexec/rapportd"),
    ClassifyEntry(command: "Dropbox", comm: "Dropbox", port: 17600, args: "/Applications/Dropbox.app/Contents/MacOS/Dropbox"),
    ClassifyEntry(command: "DropboxFi", comm: "Dropbox", port: 17500, args: "Dropbox"),
    ClassifyEntry(command: "Cursor", comm: "Cursor", port: 57631, args: "Cursor Helper"),
    ClassifyEntry(command: "Figma", comm: "Figma", port: 3845, args: "Figma"),
    ClassifyEntry(command: "Raycast", comm: "Raycast", port: 7265, args: "Raycast"),
    ClassifyEntry(command: "AdobeReso", comm: "AdobeResourceSynchronizer", port: 19292, args: "AdobeResourceSynchronizer"),
    ClassifyEntry(command: "postgres", comm: "postgres", port: 5432, args: "postgres -D /usr/local/var/postgres"),
    ClassifyEntry(command: "redis-ser", comm: "redis-server", port: 6379, args: "redis-server"),
])
func hidesMachineServices(_ entry: ClassifyEntry) {
    let verdict = classify(entry)
    #expect(verdict.canKill == false)
    #expect(verdict.confidence == "hide")
}

@Test func keepsNextServer() {
    let verdict = classify(ClassifyEntry(
        command: "node",
        comm: "node",
        port: 3000,
        args: "next-server",
        cwd: "/Users/dev/Documents/Apps/marketing",
        projectFile: true
    ))
    #expect(verdict.kind == "dev")
    #expect(verdict.canKill == true)
    #expect(verdict.confidence == "high")
}

@Test func keepsVite() {
    let verdict = classify(ClassifyEntry(
        command: "node",
        comm: "node",
        port: 5173,
        args: "node /Users/dev/app/node_modules/.bin/vite",
        projectFile: true
    ))
    #expect(verdict.kind == "dev")
    #expect(verdict.canKill == true)
}

@Test func keepsUvicorn() {
    let verdict = classify(ClassifyEntry(
        command: "python3",
        comm: "python3",
        port: 8000,
        args: "python3 -m uvicorn app.main:app --reload",
        projectFile: true
    ))
    #expect(verdict.canKill == true)
    #expect(verdict.kind == "dev")
}

@Test func keepsPythonHttpServer() {
    let verdict = classify(ClassifyEntry(
        command: "python3",
        comm: "python3",
        port: 8000,
        args: "python3 -m http.server 8000"
    ))
    #expect(verdict.canKill == true)
}

@Test func port5000AloneIsNotDev() {
    let verdict = classify(ClassifyEntry(
        command: "somebin",
        comm: "somebin",
        port: 5000,
        args: "somebin --listen"
    ))
    #expect(verdict.canKill == false)
}

@Test func commandNameStillMatchesWhenCommIsPresent() {
    let verdict = classify(ClassifyEntry(
        command: "rapportd",
        comm: "rapportd",
        port: 51753,
        args: "/usr/libexec/rapportd"
    ))
    #expect(verdict.kind == "system")
    #expect(verdict.canKill == false)
}

@Test func promotesNodeWithDevHttpFingerprint() {
    let verdict = classify(ClassifyEntry(
        command: "node",
        comm: "node",
        port: 3412,
        args: "node server.js",
        http: HttpInfo(ok: true, status: 200, dev: true)
    ))
    #expect(verdict.canKill == true)
}

@Test func namesNextFromArgv() {
    #expect(inferFramework(ClassifyEntry(command: "node", comm: "node", args: "next-server")) == "next")
}

@Test func usesProjectFolderNotSrc() {
    #expect(projectName("/Users/dev/Documents/Apps/marketing/src") == "marketing")
    #expect(projectName("/Users/dev/Documents/Apps/web") == "web")
}

@Test func parsesLsofListenersAndIPv6() {
    let stdout = [
        "COMMAND     PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME",
        "node      12345  dev   23u  IPv4 0xabc      0t0  TCP 127.0.0.1:3000 (LISTEN)",
        "node      12345  dev   24u  IPv6 0xdef      0t0  TCP [::1]:3000 (LISTEN)",
        "ControlCe   797  dev   12u  IPv4 0xaaa      0t0  TCP *:5000 (LISTEN)",
    ].joined(separator: "\n")
    let rows = parseLsof(stdout)
    #expect(rows.count == 3)
    #expect(rows[0].port == 3000)
    #expect(rows[0].pid == 12345)
    #expect(rows[2].command == "ControlCe")
}

@Test func parsesPsRowsWithSpaces() {
    let stdout = " 12345  88  1.2  0.4 190000 01:02:03 /usr/local/bin/node next-server\n"
    let processes = parsePs(stdout)
    let proc = processes[12345]
    #expect(proc?.cpu == 1.2)
    #expect(proc?.rssKb == 190000)
    #expect(proc?.args.contains("next-server") == true)
}

@Test func formatsElapsedAndMemory() {
    #expect(formatElapsed("2-03:01:04") == "2d 3h")
    #expect(formatElapsed("03:01:04") == "3h 1m")
    #expect(formatElapsed("12:04") == "12m")
    #expect(formatElapsed("00:09") == "9s")
    #expect(formatRss(2048) == "2 MB")
    #expect(formatRss(512) == "512 KB")
}

@Test func matchesLocalhostLoopbackAndSubdomains() {
    #expect(urlMatchesPort("http://localhost:3000/", 3000))
    #expect(urlMatchesPort("http://localhost:3000/dashboard?tab=1", 3000))
    #expect(urlMatchesPort("https://127.0.0.1:5173/app", 5173))
    #expect(urlMatchesPort("http://[::1]:8080/", 8080))
    #expect(urlMatchesPort("http://marketing.localhost:3000/", 3000))
    #expect(urlMatchesPort("http://localhost/", 80))
}

@Test func rejectsDifferentPortHostOrScheme() {
    #expect(!urlMatchesPort("http://localhost:30000/", 3000))
    #expect(!urlMatchesPort("http://localhost:3000/", 30000))
    #expect(!urlMatchesPort("http://example.com:3000/", 3000))
    #expect(!urlMatchesPort("http://localhost:3000/", 5173))
    #expect(!urlMatchesPort("file:///tmp/index.html", 3000))
    #expect(!urlMatchesPort("not a url", 3000))
}

@Test func choosesTheActiveTabInTheFrontWindow() throws {
    let tabs = parseTabList([
        "10\t1\t0\thttp://localhost:3000/old",
        "10\t2\t1\thttp://localhost:3000/current",
        "10\t3\t0\thttp://localhost:30000/",
        "4\t1\t1\thttp://127.0.0.1:5173/",
    ].joined(separator: "\n"))
    let chosen = chooseTab(tabs, 3000)
    #expect(chosen?.windowId == 10)
    #expect(chosen?.tabIndex == 2)
    #expect(chosen?.url == "http://localhost:3000/current")

    let background = chooseTab(tabs, 5173)
    #expect(background?.windowId == 4)
    #expect(background?.tabIndex == 1)
    #expect(chooseTab(tabs, 9999) == nil)
}

@Test func browserScriptsOnlyAddressKnownBrowsers() throws {
    let safari = try listScript("Safari")
    #expect(safari.contains(#"tell application "Safari""#))
    let arc = try activateScript("Arc", 12, 3)
    #expect(arc.contains(#"tell application "Arc""#))
    let chrome = try activateScript("Google Chrome", 8, 1)
    #expect(chrome.contains("active tab index of w to 1"))
    #expect(throws: OpenError.unknownBrowser) {
        try listScript(#"Chrome" & delete"#)
    }
    #expect(throws: OpenError.invalidTab) {
        try activateScript("Safari", 0, 1)
    }
}

@Test @MainActor func rendersThePanelStates() throws {
    FontRegistration.register()
    let directory = URL(fileURLWithPath: "/tmp/still-up-fixtures", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try renderPanel("three", servers: [
        fixture(101, 3000, "next · marketing", 3.4, "186 MB", "2h 14m", true, "dev"),
        fixture(202, 5173, "vite · web", 1.1, "92 MB", "38m", true, "dev"),
        fixture(303, 8000, "python · sandbox", 0.2, "41 MB", "6h", true, "maybe"),
    ], to: directory)
    try renderPanel("empty", servers: [], to: directory)
    try renderPanel("unsure", servers: [
        fixture(101, 3000, "next · marketing", 3.4, "186 MB", "2h 14m", true, "dev"),
        fixture(303, 8000, "python · sandbox", 0.2, "41 MB", "6h", true, "maybe"),
    ], to: directory)
    try renderPanel("dense", servers: [
        fixture(101, 3000, "next · marketing", 3.4, "186 MB", "2h 14m", true, "dev"),
        fixture(202, 5173, "vite · web", 1.1, "92 MB", "38m", true, "dev"),
        fixture(303, 8000, "python · sandbox", 0.2, "41 MB", "6h", true, "maybe"),
        fixture(404, 4200, "ng · admin", 0.8, "71 MB", "12m", true, "dev"),
        fixture(505, 8787, "storybook · ui", 2.1, "128 MB", "51m", true, "dev"),
        fixture(606, 9229, "node · inspect", 0.1, "38 MB", "9m", false, "dev"),
    ], to: directory)
}

@MainActor
private func renderPanel(_ name: String, servers: [Server], to directory: URL) throws {
    let model = AppModel()
    let now = Date()
    model.now = now
    model.hasScanned = true
    model.result = ScanResult(scannedAt: now.addingTimeInterval(-1.2), servers: servers)
    let view = PopoverView(model: model) { _ in }
        .background(Color(red: 8 / 255, green: 10 / 255, blue: 14 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    renderer.proposedSize = ProposedViewSize(width: 336, height: nil)
    guard let image = renderer.nsImage,
          let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:])
    else {
        Issue.record("Could not render \(name)")
        return
    }
    try png.write(to: directory.appendingPathComponent("\(name).png"))
    #expect(image.size.width == 336)
    #expect(image.size.height > 80)
}

private func fixture(
    _ pid: Int32,
    _ port: Int,
    _ title: String,
    _ cpu: Double,
    _ rss: String,
    _ elapsed: String,
    _ http: Bool,
    _ kind: String
) -> Server {
    Server(
        pid: pid,
        port: port,
        command: "node",
        args: "",
        cwd: "",
        project: "",
        framework: "",
        title: title,
        cpu: cpu,
        rss: rss,
        rssKb: 0,
        elapsed: elapsed,
        http: http,
        httpDev: http,
        kind: kind,
        confidence: "show",
        reason: "dev server",
        canKill: true,
        score: 3
    )
}
