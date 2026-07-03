import Foundation
import SwiftUI

/// ponytail: single JSON file, full rewrite on save — fine for a few babies/entries; upgrade to incremental writes if the log grows large.
final class NightStore: ObservableObject {
    @Published private(set) var babies: [Baby] = []

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("NightTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = fileURL ?? dir.appendingPathComponent("store.json")
        load()
        if babies.isEmpty {
            babies = SeedData.makeSeedBabies()
            save()
        }
    }

    var sortedBabies: [Baby] {
        babies.sorted { $0.sortIndex < $1.sortIndex }
    }

    func baby(id: UUID?) -> Baby? {
        guard let id else { return sortedBabies.first }
        return babies.first { $0.id == id }
    }

    func addBaby(name: String) -> Baby {
        let baby = Baby(name: name, sortIndex: (babies.map(\.sortIndex).max() ?? -1) + 1)
        babies.append(baby)
        save()
        return baby
    }

    func renameBaby(id: UUID, name: String) {
        guard let index = babies.firstIndex(where: { $0.id == id }) else { return }
        babies[index].name = name
        save()
    }

    func deleteBaby(id: UUID) {
        babies.removeAll { $0.id == id }
        save()
    }

    func addEntry(babyID: UUID, entry: WakeEntry) {
        guard let index = babies.firstIndex(where: { $0.id == babyID }) else { return }
        babies[index].entries.append(entry)
        save()
    }

    func addDose(babyID: UUID, dose: MedDose) {
        guard let index = babies.firstIndex(where: { $0.id == babyID }) else { return }
        babies[index].doses.append(dose)
        save()
    }

    func deleteDose(babyID: UUID, doseID: UUID) {
        guard let index = babies.firstIndex(where: { $0.id == babyID }) else { return }
        babies[index].doses.removeAll { $0.id == doseID }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        babies = (try? JSONDecoder().decode([Baby].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(babies) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
