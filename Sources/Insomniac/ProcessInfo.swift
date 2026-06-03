import Foundation

struct BlockingProcess: Identifiable {
    let id: Int32
    let name: String
    let assertionType: String
    let assertionName: String
    let duration: String
    let parentName: String?

    var displayName: String {
        let label = parentName ?? name
        return "\(label) — 已持续 \(humanDuration)"
    }

    private var humanDuration: String {
        let parts = duration.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3 else { return duration }
        let (h, m, s) = (parts[0], parts[1], parts[2])
        if h > 0 { return "\(h)h\(m)m" }
        if m > 0 { return "\(m)m\(s)s" }
        return "\(s)s"
    }
}
