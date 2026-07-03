import Foundation

/// Helpers for grouping entries into "nights". A night runs from 6pm one day
/// to noon the next, which is the window parents actually care about.
enum NightWindow {
    static let startHour = 18  // 6pm
    static let endHour = 12    // noon next day

    /// The start date of the night that `date` belongs to.
    static func nightStart(for date: Date, calendar: Calendar = .current) -> Date {
        let hour = calendar.component(.hour, from: date)
        let startOfDay = calendar.startOfDay(for: date)
        if hour < endHour {
            // Early morning -> belongs to the previous evening's night.
            let prevDay = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
            return calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: prevDay) ?? prevDay
        }
        return calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: startOfDay) ?? startOfDay
    }

    /// Entries that fall within the most recent night relative to `now`.
    static func entriesTonight(_ entries: [WakeEntry], now: Date = Date(), calendar: Calendar = .current) -> [WakeEntry] {
        let start = nightStart(for: now, calendar: calendar)
        return entries.filter { $0.timestamp >= start }.sorted { $0.timestamp > $1.timestamp }
    }
}
