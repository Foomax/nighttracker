import XCTest
@testable import NightTracker

final class AnalyticsTests: XCTestCase {
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.minute = minute
        return calendar.date(from: comps) ?? .now
    }

    private func entry(_ d: Date, _ reasons: [WakeReason] = [], note: String = "") -> WakeEntry {
        WakeEntry(timestamp: d, reasons: reasons, note: note)
    }

    func testTotalWakeups() {
        let entries = [entry(date(2026, 6, 1, 2, 0)), entry(date(2026, 6, 1, 4, 0))]
        XCTAssertEqual(Analytics.totalWakeups(entries), 2)
    }

    func testAveragePerNightCountsDistinctNights() {
        // Two wakeups on the same night, one on another night => 3 / 2 = 1.5
        let entries = [
            entry(date(2026, 6, 1, 2, 0)),
            entry(date(2026, 6, 1, 4, 0)),
            entry(date(2026, 6, 2, 3, 0))
        ]
        XCTAssertEqual(Analytics.averagePerNight(entries, calendar: calendar), 1.5, accuracy: 0.0001)
    }

    func testMostCommonReason() {
        let entries = [
            entry(date(2026, 6, 1, 2, 0), [.hunger]),
            entry(date(2026, 6, 1, 4, 0), [.hunger, .diaper]),
            entry(date(2026, 6, 2, 3, 0), [.diaper])
        ]
        // hunger=2, diaper=2 -> tie broken deterministically (lexicographically smaller wins in max comparator)
        XCTAssertNotNil(Analytics.mostCommonReason(entries))
        // make hunger strictly dominant
        let entries2 = entries + [entry(date(2026, 6, 3, 1, 0), [.hunger])]
        XCTAssertEqual(Analytics.mostCommonReason(entries2), .hunger)
    }

    func testHistogramBucketsInto30MinSlots() {
        let entries = [
            entry(date(2026, 6, 1, 2, 10)), // bucket 120
            entry(date(2026, 6, 1, 2, 45)), // bucket 150
            entry(date(2026, 6, 1, 2, 50))  // bucket 150
        ]
        let buckets = Analytics.wakeupHistogram(entries, calendar: calendar)
        XCTAssertEqual(buckets.count, 48)
        XCTAssertEqual(buckets.first { $0.id == 120 }?.count, 1)
        XCTAssertEqual(buckets.first { $0.id == 150 }?.count, 2)
        XCTAssertEqual(buckets.first { $0.id == 0 }?.count, 0)
    }

    func testAverageWakeMinutesWrapsPastMidnight() {
        // 23:00 and 01:00 should average near midnight (00:00), not noon.
        let entries = [entry(date(2026, 6, 1, 23, 0)), entry(date(2026, 6, 2, 1, 0))]
        let avg = Analytics.averageWakeMinutesOfDay(entries, calendar: calendar)
        XCTAssertEqual(avg, 0) // midnight
    }

    func testReasonBreakdownSortedDescending() {
        let entries = [
            entry(date(2026, 6, 1, 2, 0), [.hunger, .diaper]),
            entry(date(2026, 6, 1, 4, 0), [.hunger])
        ]
        let breakdown = Analytics.reasonBreakdown(entries)
        XCTAssertEqual(breakdown.first?.reason, .hunger)
        XCTAssertEqual(breakdown.first?.count, 2)
    }

    func testInsightNilWhenNoEntries() {
        XCTAssertNil(Analytics.insight(for: "Baby Aria", entries: []))
    }
}

final class MedDoseTests: XCTestCase {
    func testSecondsRemainingCountsDown() {
        let now = Date.now
        let dose = MedDose(kind: .ibuprofen, timestamp: now, intervalHours: 4)
        // 1 hour later, 3 hours should remain.
        let oneHourLater = now.addingTimeInterval(3600)
        XCTAssertEqual(dose.secondsRemaining(now: oneHourLater), 3 * 3600, accuracy: 1)
        XCTAssertFalse(dose.isReady(now: oneHourLater))
    }

    func testReadyAfterInterval() {
        let now = Date.now
        let dose = MedDose(kind: .paracetamol, timestamp: now, intervalHours: 4)
        let later = now.addingTimeInterval(4 * 3600 + 1)
        XCTAssertTrue(dose.isReady(now: later))
        XCTAssertEqual(dose.secondsRemaining(now: later), 0)
    }

    func testCustomNameDisplay() {
        let dose = MedDose(kind: .other, customName: "Vitamin D", intervalHours: 24)
        XCTAssertEqual(dose.displayName, "Vitamin D")
        let fallback = MedDose(kind: .other, customName: "  ", intervalHours: 24)
        XCTAssertEqual(fallback.displayName, "Other")
    }
}

final class NightWindowTests: XCTestCase {
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal
    }()

    private func date(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = day; comps.hour = hour; comps.minute = minute
        return calendar.date(from: comps) ?? .now
    }

    func testEarlyMorningBelongsToPreviousEvening() {
        let twoAM = date(2, 2, 0)
        let start = NightWindow.nightStart(for: twoAM, calendar: calendar)
        XCTAssertEqual(start, date(1, 18, 0)) // 6pm the day before
    }

    func testEveningStartsItsOwnNight() {
        let ninePM = date(2, 21, 0)
        let start = NightWindow.nightStart(for: ninePM, calendar: calendar)
        XCTAssertEqual(start, date(2, 18, 0))
    }
}
