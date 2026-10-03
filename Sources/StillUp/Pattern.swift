import Foundation

struct Pattern: @unchecked Sendable {
    private let regex: NSRegularExpression

    init(_ pattern: String, caseInsensitive: Bool = false) {
        var options: NSRegularExpression.Options = []
        if caseInsensitive { options.insert(.caseInsensitive) }
        regex = try! NSRegularExpression(pattern: pattern, options: options)
    }

    func matches(_ value: String) -> Bool {
        let range = NSRange(value.startIndex..., in: value)
        return regex.firstMatch(in: value, range: range) != nil
    }
}

func matchesAny(_ value: String, _ patterns: [Pattern]) -> Bool {
    if value.isEmpty { return false }
    return patterns.contains { $0.matches(value) }
}

func firstGroups(_ pattern: String, in value: String) -> [String]? {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(value.startIndex..., in: value)
    guard let match = regex.firstMatch(in: value, range: range) else { return nil }
    return (0..<match.numberOfRanges).map { index in
        let piece = match.range(at: index)
        guard piece.location != NSNotFound, let swiftRange = Range(piece, in: value) else { return "" }
        return String(value[swiftRange])
    }
}
