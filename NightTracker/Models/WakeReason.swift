import SwiftUI

/// Selectable reasons a baby woke up. Each carries an SF Symbol and a short label.
enum WakeReason: String, CaseIterable, Identifiable, Codable {
    case hunger
    case diaper
    case temperature
    case tummy
    case comfort
    case fever
    case disruptedSleep

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hunger: return "Hunger"
        case .diaper: return "Wet / Diaper"
        case .temperature: return "Too Hot / Cold"
        case .tummy: return "Tummy"
        case .comfort: return "Comfort"
        case .fever: return "Fever"
        case .disruptedSleep: return "Disrupted Sleep"
        }
    }

    var icon: String {
        switch self {
        case .hunger: return "drop.fill"
        case .diaper: return "humidity.fill"
        case .temperature: return "thermometer.medium"
        case .tummy: return "wind"
        case .comfort: return "heart.fill"
        case .fever: return "thermometer.sun.fill"
        case .disruptedSleep: return "moon.zzz.fill"
        }
    }
}
