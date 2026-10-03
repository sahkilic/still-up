import Foundation

let devPorts: Set<Int> = [
    1234, 1337, 24678, 3000, 3001, 3002, 3003, 3010, 3333, 4000, 4001, 4173,
    4200, 4321, 4444, 5001, 5173, 5174, 5175, 6006, 6969, 8000, 8001, 8080,
    8081, 8082, 8088, 8787, 8888, 9000, 9001, 9090, 9229, 9292, 9411, 1420,
]

let excludePorts: Set<Int> = [
    22, 53, 88, 110, 143, 443, 445, 465, 548, 587, 631, 993, 995, 2049, 3283,
    3478, 3689, 5000, 5353, 5900, 7000, 7243, 17500, 17600, 17603,
]

let systemCommands: [Pattern] = [
    Pattern(#"^ControlCe"#, caseInsensitive: true),
    Pattern(#"^Control Center$"#, caseInsensitive: true),
    Pattern(#"^rapportd$"#, caseInsensitive: true),
    Pattern(#"^sharingd$"#, caseInsensitive: true),
    Pattern(#"^identityservicesd$"#, caseInsensitive: true),
    Pattern(#"^bluetoothd$"#, caseInsensitive: true),
    Pattern(#"^coreaudiod$"#, caseInsensitive: true),
    Pattern(#"^WindowServer$"#, caseInsensitive: true),
    Pattern(#"^launchd$"#, caseInsensitive: true),
    Pattern(#"^syslogd$"#, caseInsensitive: true),
    Pattern(#"^configd$"#, caseInsensitive: true),
    Pattern(#"^mDNSResponder$"#, caseInsensitive: true),
    Pattern(#"^cupsd$"#, caseInsensitive: true),
    Pattern(#"^AirPlay"#, caseInsensitive: true),
    Pattern(#"^nsurlsessiond$"#, caseInsensitive: true),
    Pattern(#"^fileproviderd$"#, caseInsensitive: true),
    Pattern(#"^EEventMan"#, caseInsensitive: true),
    Pattern(#"^Adobe"#, caseInsensitive: true),
    Pattern(#"^Creative Cloud"#, caseInsensitive: true),
    Pattern(#"^Raycast$"#, caseInsensitive: true),
    Pattern(#"^Cursor$"#, caseInsensitive: true),
    Pattern(#"^Cursor Helper"#, caseInsensitive: true),
    Pattern(#"^Code$"#, caseInsensitive: true),
    Pattern(#"^Code Helper"#, caseInsensitive: true),
    Pattern(#"^Electron$"#, caseInsensitive: true),
    Pattern(#"^Dropbox"#, caseInsensitive: true),
    Pattern(#"^Figma$"#, caseInsensitive: true),
    Pattern(#"^figma_"#, caseInsensitive: true),
    Pattern(#"^Slack"#, caseInsensitive: true),
    Pattern(#"^Discord"#, caseInsensitive: true),
    Pattern(#"^Spotify"#, caseInsensitive: true),
    Pattern(#"^1Password"#, caseInsensitive: true),
    Pattern(#"^Chrome$"#, caseInsensitive: true),
    Pattern(#"^Google Chrome"#, caseInsensitive: true),
    Pattern(#"^Chromium$"#, caseInsensitive: true),
    Pattern(#"^Safari$"#, caseInsensitive: true),
    Pattern(#"^firefox$"#, caseInsensitive: true),
    Pattern(#"^zoom"#, caseInsensitive: true),
    Pattern(#"^Microsoft"#, caseInsensitive: true),
    Pattern(#"^Teams$"#, caseInsensitive: true),
    Pattern(#"^Notion"#, caseInsensitive: true),
    Pattern(#"^Linear$"#, caseInsensitive: true),
    Pattern(#"^Docker$"#, caseInsensitive: true),
    Pattern(#"^com\.docker"#, caseInsensitive: true),
    Pattern(#"^vpnkit$"#, caseInsensitive: true),
    Pattern(#"^qemu-system"#, caseInsensitive: true),
    Pattern(#"^OrbStack"#, caseInsensitive: true),
    Pattern(#"^lsof$"#, caseInsensitive: true),
    Pattern(#"^localhost$"#, caseInsensitive: true),
    Pattern(#"^dev-server-checker$"#, caseInsensitive: true),
]

let serviceCommands: [Pattern] = [
    Pattern(#"^postgres"#, caseInsensitive: true),
    Pattern(#"^postmaster$"#, caseInsensitive: true),
    Pattern(#"^redis-server$"#, caseInsensitive: true),
    Pattern(#"^redis$"#, caseInsensitive: true),
    Pattern(#"^mongod$"#, caseInsensitive: true),
    Pattern(#"^mysql"#, caseInsensitive: true),
    Pattern(#"^mariadbd$"#, caseInsensitive: true),
    Pattern(#"^elasticsearch"#, caseInsensitive: true),
    Pattern(#"^opensearch"#, caseInsensitive: true),
    Pattern(#"^clickhouse"#, caseInsensitive: true),
    Pattern(#"^memcached$"#, caseInsensitive: true),
    Pattern(#"^rabbitmq"#, caseInsensitive: true),
    Pattern(#"^nats-server$"#, caseInsensitive: true),
    Pattern(#"^kafka"#, caseInsensitive: true),
    Pattern(#"^zookeeper"#, caseInsensitive: true),
    Pattern(#"^minio$"#, caseInsensitive: true),
    Pattern(#"^vault$"#, caseInsensitive: true),
    Pattern(#"^consul$"#, caseInsensitive: true),
    Pattern(#"^sshd$"#, caseInsensitive: true),
    Pattern(#"^nginx$"#, caseInsensitive: true),
    Pattern(#"^httpd$"#, caseInsensitive: true),
    Pattern(#"^apache2$"#, caseInsensitive: true),
    Pattern(#"^caddy$"#, caseInsensitive: true),
    Pattern(#"^traefik$"#, caseInsensitive: true),
    Pattern(#"^cloudflared$"#, caseInsensitive: true),
    Pattern(#"^tailscaled$"#, caseInsensitive: true),
    Pattern(#"^syncthing$"#, caseInsensitive: true),
    Pattern(#"^Plex"#, caseInsensitive: true),
    Pattern(#"^ollama$"#, caseInsensitive: true),
]

let devCommands: [Pattern] = [
    Pattern(#"^node$"#, caseInsensitive: true),
    Pattern(#"^nodejs$"#, caseInsensitive: true),
    Pattern(#"^next-server$"#, caseInsensitive: true),
    Pattern(#"^next$"#, caseInsensitive: true),
    Pattern(#"^bun$"#, caseInsensitive: true),
    Pattern(#"^deno$"#, caseInsensitive: true),
    Pattern(#"^python\d*"#, caseInsensitive: true),
    Pattern(#"^ruby$"#, caseInsensitive: true),
    Pattern(#"^php$"#, caseInsensitive: true),
    Pattern(#"^perl$"#, caseInsensitive: true),
    Pattern(#"^java$"#, caseInsensitive: true),
    Pattern(#"^jshell$"#, caseInsensitive: true),
    Pattern(#"^go$"#, caseInsensitive: true),
    Pattern(#"^air$"#, caseInsensitive: true),
    Pattern(#"^cargo$"#, caseInsensitive: true),
    Pattern(#"^vite$"#, caseInsensitive: true),
    Pattern(#"^webpack$"#, caseInsensitive: true),
    Pattern(#"^esbuild$"#, caseInsensitive: true),
    Pattern(#"^parcel$"#, caseInsensitive: true),
    Pattern(#"^turbo$"#, caseInsensitive: true),
    Pattern(#"^wrangler$"#, caseInsensitive: true),
    Pattern(#"^astro$"#, caseInsensitive: true),
    Pattern(#"^remix$"#, caseInsensitive: true),
    Pattern(#"^nuxt$"#, caseInsensitive: true),
    Pattern(#"^nest$"#, caseInsensitive: true),
    Pattern(#"^tsx$"#, caseInsensitive: true),
    Pattern(#"^ts-node$"#, caseInsensitive: true),
    Pattern(#"^nodemon$"#, caseInsensitive: true),
    Pattern(#"^puma$"#, caseInsensitive: true),
    Pattern(#"^unicorn$"#, caseInsensitive: true),
    Pattern(#"^rackup$"#, caseInsensitive: true),
    Pattern(#"^uvicorn$"#, caseInsensitive: true),
    Pattern(#"^gunicorn$"#, caseInsensitive: true),
    Pattern(#"^hypercorn$"#, caseInsensitive: true),
    Pattern(#"^daphne$"#, caseInsensitive: true),
    Pattern(#"^granian$"#, caseInsensitive: true),
    Pattern(#"^flask$"#, caseInsensitive: true),
    Pattern(#"^django$"#, caseInsensitive: true),
    Pattern(#"^manage\.py$"#, caseInsensitive: true),
    Pattern(#"^rails$"#, caseInsensitive: true),
    Pattern(#"^spring$"#, caseInsensitive: true),
    Pattern(#"^gradle"#, caseInsensitive: true),
    Pattern(#"^mvn$"#, caseInsensitive: true),
    Pattern(#"^sbt$"#, caseInsensitive: true),
    Pattern(#"^dotnet$"#, caseInsensitive: true),
]

let devArgPatterns: [Pattern] = [
    Pattern(#"next-server"#),
    Pattern(#"next\s+dev\b"#),
    Pattern(#"["']dev["']"#),
    Pattern(#"\brun\s+dev\b"#),
    Pattern(#"\b(pnpm|yarn|npm)\s+dev\b"#),
    Pattern(#"\bstart:dev\b"#),
    Pattern(#"\bvite\b"#),
    Pattern(#"webpack-dev-server"#),
    Pattern(#"webpack\.dev"#),
    Pattern(#"\bnodemon\b"#),
    Pattern(#"\btsx\b"#),
    Pattern(#"\bts-node\b"#),
    Pattern(#"@remix-run"#),
    Pattern(#"\bastro\b"#),
    Pattern(#"\bnuxt\b"#),
    Pattern(#"\bnest\s+start\b"#),
    Pattern(#"storybook"#),
    Pattern(#"prisma\s+studio"#),
    Pattern(#"wrangler"#),
    Pattern(#"manage\.py\s+runserver"#),
    Pattern(#"\brails\s+s(erver)?\b"#),
    Pattern(#"\bpuma\b"#),
    Pattern(#"\bunicorn\b"#),
    Pattern(#"\buvicorn\b"#),
    Pattern(#"\bgunicorn\b"#),
    Pattern(#"\bflask(\s+run)?\b"#),
    Pattern(#"\bfastapi\b"#),
    Pattern(#"\bcargo\s+watch\b"#),
    Pattern(#"\bair\b"#),
    Pattern(#"http\.server"#),
    Pattern(#"live-server"#),
    Pattern(#"json-server"#),
    Pattern(#"\besbuild\b.*--(serv|watch)"#),
    Pattern(#"parcel\s+serve"#),
    Pattern(#"\bremix\s+vite:dev\b"#),
    Pattern(#"react-scripts\s+start"#),
    Pattern(#"vue-cli-service\s+serve"#),
    Pattern(#"ng\s+serve"#),
    Pattern(#"ember\s+serve"#),
    Pattern(#"php\s+-S\b"#),
    Pattern(#"bin\/rails"#),
    Pattern(#"sidekiq"#),
    Pattern(#"daphne"#),
    Pattern(#"hypercorn"#),
    Pattern(#"granian"#),
    Pattern(#"\b--watch\b"#),
    Pattern(#"\b--hot\b"#),
    Pattern(#"webpack-hot"#),
]

let serviceArgPatterns: [Pattern] = [
    Pattern(#"\bpostgres\b"#),
    Pattern(#"\bredis-server\b"#),
    Pattern(#"\bmongod\b"#),
    Pattern(#"\belasticsearch\b"#),
    Pattern(#"\bopensearch\b"#),
    Pattern(#"\bmysqld\b"#),
    Pattern(#"\bkafka\b"#),
    Pattern(#"\bLanguageServer\b"#),
    Pattern(#"\blanguage.server\b"#, caseInsensitive: true),
    Pattern(#"\btsserver\b"#),
    Pattern(#"\bextensionHost\b"#),
    Pattern(#"\bfileWatcher\b"#),
    Pattern(#"\bCursor Helper\b"#),
    Pattern(#"\bCode Helper\b"#),
    Pattern(#"\bAdobe"#),
    Pattern(#"\bDropbox\b"#),
    Pattern(#"\bFigma\b"#),
    Pattern(#"\bRaycast\b"#),
    Pattern(#"\bControl Center\b"#),
    Pattern(#"\bAirPlay\b"#),
    Pattern(#"\bJetBrains\b"#),
    Pattern(#"idea_rt"#),
    Pattern(#"intellij"#, caseInsensitive: true),
    Pattern(#"\bLanguageSupport\b"#),
]

let devHttpMarkers: [Pattern] = [
    Pattern(#"x-powered-by:\s*(next\.js|express|nuxt|vite|astro|remix|nestjs)"#, caseInsensitive: true),
    Pattern(#"server:\s*(vite|webpack|air|werkzeug|uvicorn|puma|waitress)"#, caseInsensitive: true),
    Pattern(#"<title>[^<]*(vite|next\.js|nuxt|remix|astro|webpack|storybook)"#, caseInsensitive: true),
    Pattern(#"__NEXT_DATA__"#),
    Pattern(#"@vite\/client"#),
    Pattern(#"webpack-dev-server"#),
    Pattern(#"webpackHotUpdate"#),
    Pattern(#"_nuxt\/"#),
    Pattern(#"@react-refresh"#),
    Pattern(#"__remix"#),
    Pattern(#"django"#),
    Pattern(#"flask"#),
    Pattern(#"Rails"#),
]

private let frameworkChecks: [(Pattern, String)] = [
    (Pattern(#"next-server|\bnext\s+dev\b|next\/dist"#), "next"),
    (Pattern(#"\bvite\b"#), "vite"),
    (Pattern(#"webpack-dev-server|webpack"#), "webpack"),
    (Pattern(#"\bnuxt\b"#), "nuxt"),
    (Pattern(#"\bastro\b"#), "astro"),
    (Pattern(#"remix"#), "remix"),
    (Pattern(#"storybook"#), "storybook"),
    (Pattern(#"prisma\s+studio"#), "prisma"),
    (Pattern(#"\buvicorn\b|\bfastapi\b"#), "fastapi"),
    (Pattern(#"\bflask\b|werkzeug"#), "flask"),
    (Pattern(#"manage\.py|django"#), "django"),
    (Pattern(#"\brails\b|\bpuma\b"#), "rails"),
    (Pattern(#"\bnest\b"#), "nest"),
    (Pattern(#"wrangler"#), "wrangler"),
    (Pattern(#"http\.server"#), "static"),
    (Pattern(#"\bbun\b"#), "bun"),
    (Pattern(#"\bdeno\b"#), "deno"),
    (Pattern(#"\bnode\b"#), "node"),
    (Pattern(#"python"#), "python"),
    (Pattern(#"\bruby\b"#), "ruby"),
    (Pattern(#"\bjava\b"#), "java"),
]

func inferFramework(_ entry: ClassifyEntry) -> String {
    let hay = "\(entry.command) \(entry.comm) \(entry.args)"
    for (pattern, name) in frameworkChecks {
        if pattern.matches(hay) { return name }
    }
    let fallback = entry.command.isEmpty ? entry.comm : entry.command
    if fallback.isEmpty { return "process" }
    return fallback.lowercased()
}

func projectName(_ cwd: String) -> String {
    if cwd.isEmpty { return "" }
    let parts = cwd.split(separator: "/").map(String.init)
    if parts.isEmpty { return "" }
    let last = parts[parts.count - 1]
    if last == "bin" || last == "src" || last == "app" || last == "dist" {
        return parts.count >= 2 ? parts[parts.count - 2] : last
    }
    if parts.count <= 2 && (parts[0] == "Users" || parts[0] == "home") {
        return ""
    }
    return last
}

func detectDevHttp(_ headersText: String, _ bodyText: String) -> Bool {
    let blob = "\(headersText)\n\(bodyText)"
    return devHttpMarkers.contains { $0.matches(blob) }
}

func classify(_ entry: ClassifyEntry) -> Verdict {
    let command = entry.command
    let comm = entry.comm
    let args = entry.args
    let port = entry.port
    let names = [command, comm].filter { !$0.isEmpty }

    if names.contains(where: { matchesAny($0, systemCommands) }) || matchesAny(args, serviceArgPatterns) {
        return Verdict(kind: "system", confidence: "hide", score: -100, reason: "system or app listener", canKill: false)
    }

    if names.contains(where: { matchesAny($0, serviceCommands) }) {
        return Verdict(kind: "service", confidence: "hide", score: -80, reason: "infrastructure service", canKill: false)
    }

    let devName = names.contains { matchesAny($0, devCommands) }
    if excludePorts.contains(port) && !devName && !matchesAny(args, devArgPatterns) {
        return Verdict(kind: "system", confidence: "hide", score: -60, reason: "reserved or system port", canKill: false)
    }

    var score = 0
    var reasons: [String] = []

    if devName {
        score += 28
        reasons.append("dev runtime")
    }
    if matchesAny(args, devArgPatterns) {
        score += 36
        reasons.append("dev command")
    }
    if devPorts.contains(port) {
        score += 12
        reasons.append("common dev port")
    }
    if entry.projectFile {
        score += 18
        reasons.append("project folder")
    }
    if let http = entry.http, http.ok {
        score += 10
        reasons.append("http up")
        if http.dev {
            score += 22
            reasons.append("dev http fingerprint")
        }
    }

    if score >= 40 {
        return Verdict(kind: "dev", confidence: "high", score: score, reason: reasons.joined(separator: " · "), canKill: true)
    }

    if score >= 22 && (devName || (entry.http?.ok == true)) {
        return Verdict(
            kind: "maybe",
            confidence: "medium",
            score: score,
            reason: reasons.isEmpty ? "weak match" : reasons.joined(separator: " · "),
            canKill: true
        )
    }

    return Verdict(
        kind: "unknown",
        confidence: "hide",
        score: score,
        reason: reasons.isEmpty ? "not a leftover dev server" : reasons.joined(separator: " · "),
        canKill: false
    )
}
