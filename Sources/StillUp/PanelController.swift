import AppKit
import CoreText
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    let model = AppModel()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var panel: KeyPanel!
    private var suppressNextClick = false
    private let preview: Bool
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(preview: Bool) {
        self.preview = preview
        super.init()
    }

    func start() {
        FontRegistration.register()
        model.onChange = { [weak self] in
            self?.applyTray()
        }
        model.startClock()

        let button = statusItem.button
        button?.image = TrayIcon.image(active: false)
        button?.imagePosition = .imageOnly
        button?.target = self
        button?.action = #selector(statusClick)
        button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        applyTray()

        let root = PopoverView(model: model) { [weak self] height in
            self?.resize(to: height)
        }
        let hosting = NSHostingView(rootView: root)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor

        let vibrancy = NSVisualEffectView()
        vibrancy.material = .hudWindow
        vibrancy.blendingMode = .behindWindow
        vibrancy.state = .active
        vibrancy.wantsLayer = true
        vibrancy.layer?.cornerRadius = 12
        vibrancy.layer?.masksToBounds = true
        vibrancy.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: vibrancy.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: vibrancy.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: vibrancy.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: vibrancy.bottomAnchor),
        ])

        panel = KeyPanel(
            contentRect: NSRect(x: 0, y: 0, width: 336, height: 168),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = vibrancy
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.delegate = self
        panel.isReleasedWhenClosed = false

        installMonitors()
        Task { await model.refresh() }
        if preview { show() }
    }

    @objc private func statusClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showMenu()
            return
        }
        if event.clickCount > 1 { return }
        if suppressNextClick {
            suppressNextClick = false
            return
        }
        if panel.isVisible { hide() } else { show() }
    }

    private func showMenu() {
        let menu = NSMenu()
        let status = NSMenuItem(title: model.menuLabel, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())
        let refresh = NSMenuItem(title: "Refresh", action: #selector(refreshFromMenu), keyEquivalent: "")
        refresh.target = self
        menu.addItem(refresh)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Still Up", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        if let button = statusItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button)
        }
    }

    @objc private func refreshFromMenu() {
        Task { @MainActor in
            await model.refresh()
            show()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func show() {
        resize(to: panel.frame.height)
        position()
        panel.orderFrontRegardless()
        panel.makeKey()
        model.startPolling()
        Task { await model.refresh() }
        Task { @MainActor in
            for _ in 0..<10 {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard panel.isVisible else { return }
                if position() { return }
            }
        }
    }

    private func hide() {
        guard !preview else { return }
        panel.orderOut(nil)
        model.stopPolling()
    }

    private func resize(to height: CGFloat) {
        let next = min(380, max(120, height.rounded()))
        guard abs(panel.frame.height - next) > 0.5 else { return }
        var frame = panel.frame
        let delta = next - frame.height
        frame.size = NSSize(width: 336, height: next)
        frame.origin.y -= delta
        panel.setFrame(frame, display: true)
        if panel.isVisible { position() }
    }

    @discardableResult
    private func position() -> Bool {
        guard let button = statusItem.button, let window = button.window else { return false }
        let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        let screen = NSScreen.screens.first { $0.frame.maxY >= buttonFrame.maxY - 1 && $0.frame.minY <= buttonFrame.minY } ?? NSScreen.main
        guard let screen else { return false }
        // The status item can report a placeholder frame until the menu bar lays it out.
        guard abs(buttonFrame.maxY - screen.frame.maxY) < 20, buttonFrame.width > 1 else { return false }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        var x = buttonFrame.midX - size.width / 2
        var y = buttonFrame.minY - size.height - 6
        let margin: CGFloat = 8
        x = min(x, visible.maxX - size.width - margin)
        x = max(x, visible.minX + margin)
        if y < visible.minY + margin {
            y = buttonFrame.maxY + 6
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        return true
    }

    private func applyTray() {
        let active = model.hasScanned && !model.servers.isEmpty
        statusItem.button?.image = TrayIcon.image(active: active)
        statusItem.button?.toolTip = model.hasScanned ? model.tooltip : "Still Up — all clear"
    }

    private func mouseOnStatusItem() -> Bool {
        guard let button = statusItem.button, let window = button.window else { return false }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        return frame.contains(NSEvent.mouseLocation)
    }

    private func installMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.panel.isVisible, !self.preview else { return }
                self.hide()
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown, event.keyCode == 53, self.panel.isVisible {
                self.hide()
                return nil
            }
            if event.type == .leftMouseDown || event.type == .rightMouseDown {
                let inPanel = event.window === self.panel
                if self.panel.isVisible, !inPanel, !self.mouseOnStatusItem(), !self.preview {
                    self.hide()
                }
            }
            return event
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        guard panel.isVisible, !preview else { return }
        if mouseOnStatusItem() { suppressNextClick = true }
        hide()
    }
}

private final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

enum FontRegistration {
    static func register() {
        var urls: [URL] = []
        let names = [
            "RedHatText-Regular",
            "RedHatText-Medium",
            "RedHatText-SemiBold",
            "RedHatMono-Regular",
            "RedHatMono-Medium",
        ]
        for name in names {
            if let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.module.url(forResource: name, withExtension: "ttf")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
            {
                urls.append(url)
            }
        }
        if let resource = Bundle.main.resourceURL {
            let folder = resource.appendingPathComponent("Fonts")
            if let found = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
                urls.append(contentsOf: found.filter { $0.pathExtension == "ttf" })
            }
        }
        for url in Set(urls) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
