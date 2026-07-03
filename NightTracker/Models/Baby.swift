import Foundation

/// A tracked profile. The wireframe calls these "Baby Aria / Baby Leo"; the app
/// supports any profile name (e.g. a "Parent" profile) selectable from the top picker.
struct Baby: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var createdAt: Date
    var sortIndex: Int
    var entries: [WakeEntry]
    var doses: [MedDose]

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), sortIndex: Int = 0) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.sortIndex = sortIndex
        self.entries = []
        self.doses = []
    }
}
