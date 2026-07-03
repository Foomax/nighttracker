import Foundation

/// A single logged wakeup event for a baby.
struct WakeEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var timestamp: Date
    /// Raw values of `WakeReason`; stored as strings for persistence compatibility.
    var reasonsRaw: [String]
    var note: String

    init(id: UUID = UUID(), timestamp: Date = Date(), reasons: [WakeReason] = [], note: String = "") {
        self.id = id
        self.timestamp = timestamp
        self.reasonsRaw = reasons.map(\.rawValue)
        self.note = note
    }

    var reasons: [WakeReason] {
        get { reasonsRaw.compactMap(WakeReason.init(rawValue:)) }
        set { reasonsRaw = newValue.map(\.rawValue) }
    }
}
