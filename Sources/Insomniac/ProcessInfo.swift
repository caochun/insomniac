import Foundation

struct BlockingProcess: Identifiable {
    let id: Int32
    let name: String
    let assertionType: String
    let assertionName: String
    let duration: String
    let parentName: String?

    var displayName: String {
        if let parentName {
            return "\(parentName) (via caffeinate, PID: \(id))"
        }
        return "\(name) (PID: \(id))"
    }

    var description: String {
        "\(assertionType): \(assertionName) [\(duration)]"
    }
}
