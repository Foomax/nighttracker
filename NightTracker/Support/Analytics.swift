import Foundation

/// A bucket in the 30-minute wakeup-time histogram.
struct TimeBucket: Identifiable {
    let id: Int          // minutes-of-day for the bucket start (0...1410)
    let count: Int
    var label: String {
        let hour = id / 60
        let minute = id % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}

/// Pure, side-effect-free statistics over a set of wakeups. Kept free of SwiftUI/SwiftData
/// so it can be unit-tested directly.
enum Analytics {
    /// Total number of logged wakeups.
    static func totalWakeups(_ entries: [WakeEntry]) -> Int { entries.count }

    /// Average wakeups per night across the nights that actually have entries.
    static func averagePerNight(_ entries: [WakeEntry], calendar: Calendar = .current) -> Double {
        guard !entries.isEmpty else { return 0 }
        let nights = Set(entries.map { NightWindow.nightStart(for: $0.timestamp, calendar: calendar) })
        guard !nights.isEmpty else { return 0 }
        return Double(entries.count) / Double(nights.count)
    }

    /// The most frequently selected wakeup reason, if any.
    static func mostCommonReason(_ entries: [WakeEntry]) -> WakeReason? {
        var counts: [WakeReason: Int] = [:]
        for entry in entries {
            for reason in entry.reasons { counts[reason, default: 0] += 1 }
        }
        return counts.max { lhs, rhs in
            lhs.value == rhs.value ? lhs.key.rawValue > rhs.key.rawValue : lhs.value < rhs.value
        }?.key
    }

    /// Counts of each reason, sorted most-common first.
    static func reasonBreakdown(_ entries: [WakeEntry]) -> [(reason: WakeReason, count: Int)] {
        var counts: [WakeReason: Int] = [:]
        for entry in entries {
            for reason in entry.reasons { counts[reason, default: 0] += 1 }
        }
        return counts
            .map { (reason: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.reason.rawValue < $1.reason.rawValue : $0.count > $1.count }
    }

    /// Average wake time expressed as minutes-of-day, treating post-midnight hours
    /// as a continuation of the evening so the mean doesn't get dragged toward noon.
    static func averageWakeMinutesOfDay(_ entries: [WakeEntry], calendar: Calendar = .current) -> Int? {
        guard !entries.isEmpty else { return nil }
        var total = 0
        for entry in entries {
            let comps = calendar.dateComponents([.hour, .minute], from: entry.timestamp)
            var minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            if minutes < NightWindow.endHour * 60 { minutes += 24 * 60 } // wrap early morning past midnight
            total += minutes
        }
        let avg = (total / entries.count) % (24 * 60)
        return avg
    }

    /// Histogram of wakeups bucketed into 30-minute slots across a 24h clock.
    static func wakeupHistogram(_ entries: [WakeEntry], calendar: Calendar = .current) -> [TimeBucket] {
        var counts: [Int: Int] = [:]
        for entry in entries {
            let comps = calendar.dateComponents([.hour, .minute], from: entry.timestamp)
            let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            let bucket = (minutes / 30) * 30
            counts[bucket, default: 0] += 1
        }
        return stride(from: 0, to: 24 * 60, by: 30).map { start in
            TimeBucket(id: start, count: counts[start] ?? 0)
        }
    }

    /// Human-readable insight line for the Tracker header, e.g.
    /// "Aria usually wakes around 02:10. Woke 3 times last night."
    static func insight(for name: String, entries: [WakeEntry], now: Date = Date(), calendar: Calendar = .current) -> String? {
        guard !entries.isEmpty else { return nil }
        let firstName = name.replacingOccurrences(of: "Baby ", with: "")
        var parts: [String] = []
        if let avg = averageWakeMinutesOfDay(entries, calendar: calendar) {
            let hour = avg / 60
            let minute = avg % 60
            parts.append(String(format: "%@ usually wakes around %02d:%02d.", firstName, hour, minute))
        }
        let tonight = NightWindow.entriesTonight(entries, now: now, calendar: calendar).count
        if tonight > 0 {
            parts.append("Woke \(tonight) time\(tonight == 1 ? "" : "s") tonight.")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}
