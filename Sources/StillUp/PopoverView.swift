import AppKit
import SwiftUI

struct HeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 168
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ListHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct PopoverView: View {
    var model: AppModel
    var onHeight: (CGFloat) -> Void

    var body: some View {
        let density = Density.forCount(model.servers.count)
        VStack(alignment: .leading, spacing: 0) {
            header(density)
            if model.servers.isEmpty {
                Color.clear.frame(height: 10)
                if model.hasScanned {
                    Text("Nothing leftover.")
                        .font(AppFont.text(13))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                        .padding(.bottom, 22)
                        .padding(.horizontal, 8)
                }
            } else {
                ServerList(model: model, density: density)
            }
            footer(density)
        }
        .padding(density.shell)
        .frame(width: 336, alignment: .top)
        .background(Theme.shell)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: HeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(HeightKey.self, perform: onHeight)
    }

    private func header(_ density: Density) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("Still Up")
                .font(AppFont.text(13, semibold: true))
                .tracking(0.13)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 12)
            HStack(alignment: .center, spacing: 6) {
                Text(model.countText)
                    .font(AppFont.mono(11))
                    .foregroundStyle(Theme.muted)
                refreshButton
            }
        }
        .padding(.top, 2)
        .padding(.horizontal, 4)
        .padding(.bottom, density.headerBottom)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await model.refresh() }
        } label: {
            Text("↻")
                .font(AppFont.text(13))
                .frame(width: 22, height: 22)
                .contentShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(HoverButtonStyle(hoverFill: Theme.rowHover, hoverColor: Theme.ink, rest: Theme.muted))
        .disabled(model.refreshing)
        .accessibilityLabel("Refresh")
    }

    private func footer(_ density: Density) -> some View {
        HStack(spacing: 8) {
            if model.showStopAll {
                Button {
                    Task { await model.stopAll() }
                } label: {
                    Text("Stop all")
                        .font(AppFont.text(12))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .contentShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(HoverButtonStyle(hoverFill: Theme.rowHover, hoverColor: Theme.ink, rest: Theme.muted))
                .disabled(model.stoppingAll)
            }
            Spacer(minLength: 8)
            Text(model.stampText)
                .font(AppFont.mono(10))
                .foregroundStyle(Theme.faint)
        }
        .frame(minHeight: 22)
        .padding(.top, 6)
        .padding(.horizontal, 4)
    }
}

private struct ServerList: View {
    var model: AppModel
    var density: Density
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        let measured = rows.background {
            GeometryReader { proxy in
                Color.clear.preference(key: ListHeightKey.self, value: proxy.size.height)
            }
        }
        Group {
            if let maxHeight = density.listMax, contentHeight > maxHeight {
                ScrollView { measured }
                    .frame(height: maxHeight)
            } else {
                measured
            }
        }
        .onPreferenceChange(ListHeightKey.self) { contentHeight = $0 }
    }

    private var rows: some View {
        VStack(spacing: density.rowGap) {
            ForEach(model.servers) { server in
                ServerRow(server: server, density: density, busy: model.busy.contains(server.pid)) {
                    let flags = NSEvent.modifierFlags
                    let forceNew = flags.contains(.command) || flags.contains(.control)
                    Task { await model.open(server, forceNew: forceNew) }
                } stop: {
                    Task { await model.stop(server.pid) }
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

private struct ServerRow: View {
    var server: Server
    var density: Density
    var busy: Bool
    var open: () -> Void
    var stop: () -> Void
    @State private var hovered = false

    var body: some View {
        ZStack(alignment: density.inline ? .trailing : .topTrailing) {
            Button(action: open) {
                HStack(alignment: density.inline ? .center : .top, spacing: 8) {
                    rowBody
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Color.clear.frame(width: density.kill, height: density.kill)
                }
                .padding(density.row)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(busy)
            .accessibilityLabel("Open port \(server.port)")

            Button(action: stop) {
                Text("×")
                    .font(AppFont.text(18))
                    .frame(width: density.kill, height: density.kill)
                    .contentShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(KillButtonStyle())
            .disabled(!server.canKill || busy)
            .padding(.top, density.inline ? 0 : density.row.top + 1)
            .padding(.trailing, density.row.trailing)
            .accessibilityLabel("Stop port \(server.port)")
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(hovered ? Theme.rowHover : Theme.row))
        .opacity(busy ? 0.45 : 1)
        .onHover { inside in
            hovered = inside
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onDisappear {
            if hovered {
                NSCursor.pop()
                hovered = false
            }
        }
        .help(tip.isEmpty ? "Open localhost:\(server.port)" : tip)
    }

    private var tip: String {
        [server.pid > 0 ? "pid \(server.pid)" : "", server.reason].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    @ViewBuilder
    private var rowBody: some View {
        if density.inline {
            HStack(spacing: 6) {
                Led(http: server.http, maybe: server.kind == "maybe", size: density.led)
                    .frame(width: 12, alignment: .leading)
                Text(String(server.port))
                    .font(AppFont.mono(density.port, medium: true))
                    .tracking(density.port * 0.04)
                    .foregroundStyle(Theme.ink)
                    .frame(width: 52, height: density.port, alignment: .leading)
                Text(server.title)
                    .font(AppFont.text(density.title))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(stats)
                    .font(AppFont.mono(density.stat))
                    .tracking(density.stat * 0.01)
                    .foregroundStyle(Theme.muted)
                    .fixedSize()
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                Led(http: server.http, maybe: server.kind == "maybe", size: density.led)
                    .padding(.top, density.ledMargin)
                    .frame(width: 14, alignment: .leading)
                VStack(alignment: .leading, spacing: 0) {
                    Text(String(server.port))
                        .font(AppFont.mono(density.port, medium: true))
                        .tracking(density.port * 0.04)
                        .foregroundStyle(Theme.ink)
                        .frame(height: density.port, alignment: .leading)
                    Text(server.title)
                        .font(AppFont.text(density.title))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .padding(.top, density.titleMargin)
                    Text(stats)
                        .font(AppFont.mono(density.stat))
                        .tracking(density.stat * 0.01)
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 3)
                    if server.kind == "maybe" && density.level < 3 {
                        Text("not sure this is leftover")
                            .font(AppFont.text(11))
                            .foregroundStyle(Theme.maybe)
                            .padding(.top, 3)
                    }
                }
            }
        }
    }

    private var stats: String {
        "\(formatCpu(server.cpu)) · \(server.rss) · \(server.elapsed)"
    }
}

private struct Led: View {
    var http: Bool
    var maybe: Bool
    var size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    var body: some View {
        let color = maybe ? Theme.maybe : Theme.live
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(color.opacity(maybe ? 0.26 : 0.28))
                    .frame(width: size + 6, height: size + 6)
            )
            .opacity(http && dim && !reduceMotion ? 0.45 : 1)
            .onAppear {
                guard http, !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    dim = true
                }
            }
            .help(http ? "Responding" : "Listening")
    }
}

private struct HoverButtonStyle: ButtonStyle {
    var hoverFill: Color
    var hoverColor: Color
    var rest: Color
    @State private var hovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(hovered ? hoverColor : rest)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(hovered ? hoverFill : Color.clear)
            )
            .onHover { hovered = $0 }
    }
}

private struct KillButtonStyle: ButtonStyle {
    @State private var hovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(hovered ? Theme.kill : Theme.muted)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hovered ? Theme.kill.opacity(0.18) : Color.clear)
            )
            .onHover { hovered = $0 }
    }
}

struct Density {
    var level: Int
    var port: CGFloat
    var title: CGFloat
    var stat: CGFloat
    var led: CGFloat
    var kill: CGFloat
    var rowGap: CGFloat
    var row: EdgeInsets
    var shell: EdgeInsets
    var headerBottom: CGFloat
    var titleMargin: CGFloat
    var ledMargin: CGFloat
    var listMax: CGFloat?
    var inline: Bool

    static func forCount(_ count: Int) -> Density {
        switch densityLevel(for: count) {
        case 2:
            return Density(
                level: 2, port: 18, title: 13, stat: 10, led: 6, kill: 26, rowGap: 3,
                row: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 6),
                shell: EdgeInsets(top: 10, leading: 10, bottom: 8, trailing: 10),
                headerBottom: 10, titleMargin: 4, ledMargin: 8, listMax: nil, inline: false
            )
        case 3:
            return Density(
                level: 3, port: 15, title: 12, stat: 10, led: 6, kill: 24, rowGap: 2,
                row: EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6),
                shell: EdgeInsets(top: 8, leading: 8, bottom: 7, trailing: 8),
                headerBottom: 7, titleMargin: 2, ledMargin: 5, listMax: 300, inline: false
            )
        case 4:
            return Density(
                level: 4, port: 13, title: 12, stat: 10, led: 5, kill: 22, rowGap: 2,
                row: EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6),
                shell: EdgeInsets(top: 8, leading: 8, bottom: 6, trailing: 8),
                headerBottom: 7, titleMargin: 0, ledMargin: 0, listMax: 300, inline: true
            )
        default:
            return Density(
                level: 1, port: 22, title: 13, stat: 11, led: 7, kill: 28, rowGap: 4,
                row: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 6),
                shell: EdgeInsets(top: 12, leading: 12, bottom: 10, trailing: 12),
                headerBottom: 10, titleMargin: 4, ledMargin: 8, listMax: nil, inline: false
            )
        }
    }
}

enum Theme {
    static let ink = Color.white
    static let muted = Color(red: 232 / 255, green: 238 / 255, blue: 244 / 255)
    static let faint = Color(red: 210 / 255, green: 216 / 255, blue: 224 / 255)
    static let line = Color.white.opacity(0.2)
    static let live = Color(red: 62 / 255, green: 230 / 255, blue: 160 / 255)
    static let maybe = Color(red: 255 / 255, green: 204 / 255, blue: 85 / 255)
    static let kill = Color(red: 255 / 255, green: 138 / 255, blue: 120 / 255)
    static let row = Color.white.opacity(0.16)
    static let rowHover = Color.white.opacity(0.24)
    static let shell = Color(red: 8 / 255, green: 10 / 255, blue: 14 / 255).opacity(0.88)
}

enum AppFont {
    static func text(_ size: CGFloat, semibold: Bool = false) -> Font {
        Font.custom(semibold ? "RedHatText-SemiBold" : "RedHatText-Regular", size: size)
    }

    static func mono(_ size: CGFloat, medium: Bool = false) -> Font {
        Font.custom(medium ? "RedHatMono-Medium" : "RedHatMono-Regular", size: size)
    }
}
