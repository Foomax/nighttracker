import Foundation

/// Seeds a couple of demo profiles with realistic overnight wakeups so the app
/// has something to show on first launch. Runs only when the store is empty.
enum SeedData {
    private struct Sample {
        let daysAgo: Int
        let hour: Int
        let minute: Int
        let reasons: [WakeReason]
        let note: String
    }

    static func makeSeedBabies() -> [Baby] {
        let calendar = Calendar.current
        var aria = Baby(name: "Baby Aria", sortIndex: 0)
        var leo = Baby(name: "Baby Leo", sortIndex: 1)

        func time(daysAgo: Int, hour: Int, minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let startOfDay = calendar.startOfDay(for: base)
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay) ?? base
        }

        let ariaEntries = [
            Sample(daysAgo: 0, hour: 2, minute: 14, reasons: [.hunger, .comfort], note: "Took 10 mins to settle"),
            Sample(daysAgo: 0, hour: 4, minute: 47, reasons: [.diaper], note: ""),
            Sample(daysAgo: 1, hour: 0, minute: 35, reasons: [.hunger], note: "Fed well, back to sleep quickly"),
            Sample(daysAgo: 1, hour: 3, minute: 5, reasons: [.comfort], note: ""),
            Sample(daysAgo: 2, hour: 1, minute: 50, reasons: [.hunger, .diaper], note: "Big feed"),
            Sample(daysAgo: 2, hour: 5, minute: 20, reasons: [.disruptedSleep], note: "Noise outside")
        ]
        aria.entries = ariaEntries.map {
            WakeEntry(timestamp: time(daysAgo: $0.daysAgo, hour: $0.hour, minute: $0.minute),
                      reasons: $0.reasons, note: $0.note)
        }

        let leoEntries = [
            Sample(daysAgo: 0, hour: 1, minute: 5, reasons: [.diaper], note: ""),
            Sample(daysAgo: 0, hour: 3, minute: 40, reasons: [.hunger], note: "Bottle"),
            Sample(daysAgo: 1, hour: 2, minute: 20, reasons: [.fever], note: "Slightly warm")
        ]
        leo.entries = leoEntries.map {
            WakeEntry(timestamp: time(daysAgo: $0.daysAgo, hour: $0.hour, minute: $0.minute),
                      reasons: $0.reasons, note: $0.note)
        }

        return [aria, leo]
    }
}

/// Shared, cached date formatters (creating these is expensive).
enum Format {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    static let timeAndDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a, MMM d"
        return formatter
    }()

    static func countdown(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 { return String(format: "%dh %02dm", hours, minutes) }
        if minutes > 0 { return String(format: "%dm %02ds", minutes, secs) }
        return String(format: "%ds", secs)
    }
}
