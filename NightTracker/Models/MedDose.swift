import Foundation
import SwiftUI

/// Kinds of medication the timer supports.
enum MedKind: String, CaseIterable, Identifiable, Codable {
    case ibuprofen
    case paracetamol
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ibuprofen: return "Ibuprofen"
        case .paracetamol: return "Panadol"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .ibuprofen: return "pills.fill"
        case .paracetamol: return "cross.vial.fill"
        case .other: return "capsule.fill"
        }
    }

    /// Sensible default minimum hours between doses.
    var defaultIntervalHours: Double {
        switch self {
        case .ibuprofen: return 6
        case .paracetamol: return 4
        case .other: return 4
        }
    }
}

/// A recorded medication dose with the minimum interval until the next allowed dose.
struct MedDose: Identifiable, Codable, Equatable {
    var id: UUID
    var kindRaw: String
    var customName: String
    var timestamp: Date
    /// Minimum hours until the next dose is allowed (adjustable frequency).
    var intervalHours: Double

    init(
        id: UUID = UUID(),
        kind: MedKind,
        customName: String = "",
        timestamp: Date = Date(),
        intervalHours: Double
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.customName = customName
        self.timestamp = timestamp
        self.intervalHours = intervalHours
    }

    var kind: MedKind {
        get { MedKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var displayName: String {
        if kind == .other, !customName.trimmingCharacters(in: .whitespaces).isEmpty {
            return customName
        }
        return kind.label
    }

    /// When the next dose becomes safe.
    var nextDoseDate: Date {
        timestamp.addingTimeInterval(intervalHours * 3600)
    }

    /// Seconds remaining until the next dose (clamped at 0).
    func secondsRemaining(now: Date = Date()) -> TimeInterval {
        max(0, nextDoseDate.timeIntervalSince(now))
    }

    func isReady(now: Date = Date()) -> Bool {
        secondsRemaining(now: now) <= 0
    }
}
