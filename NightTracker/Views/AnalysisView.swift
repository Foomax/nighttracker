import SwiftUI

struct AnalysisView: View {
    let baby: Baby?

    private var entries: [WakeEntry] { baby?.entries ?? [] }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if entries.isEmpty {
                        emptyState
                    } else {
                        statGrid
                        histogramCard
                        breakdownCard
                    }
                    Color.clear.frame(height: 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(baby?.name ?? "No profile")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            Text("Analysis")
                .font(.largeTitle.bold())
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 34))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("No data yet")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text("Log a few wakeups and patterns will show up here.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .cardSurface()
    }

    private var statGrid: some View {
        let avg = Analytics.averagePerNight(entries)
        let common = Analytics.mostCommonReason(entries)
        let avgMinutes = Analytics.averageWakeMinutesOfDay(entries)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(title: "Total wakeups", value: "\(Analytics.totalWakeups(entries))", icon: "moon.fill")
            StatTile(title: "Avg / night", value: String(format: "%.1f", avg), icon: "bed.double.fill")
            StatTile(title: "Usual wake time",
                     value: avgMinutes.map { String(format: "%02d:%02d", $0 / 60, $0 % 60) } ?? "—",
                     icon: "clock.fill")
            StatTile(title: "Top reason", value: common?.label ?? "—", icon: common?.icon ?? "questionmark")
        }
    }

    private var histogramCard: some View {
        let buckets = Analytics.wakeupHistogram(entries).filter { $0.count > 0 }
        let maxCount = buckets.map(\.count).max() ?? 1
        return VStack(alignment: .leading, spacing: 12) {
            Text("Wakeups by time of night")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text("30-minute increments")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            HistogramView(buckets: buckets, maxCount: maxCount)
                .frame(height: 200)
        }
        .padding(16)
        .cardSurface()
    }

    private var breakdownCard: some View {
        let breakdown = Analytics.reasonBreakdown(entries)
        let maxCount = breakdown.map(\.count).max() ?? 1
        return VStack(alignment: .leading, spacing: 14) {
            Text("Reasons for waking")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            ForEach(breakdown, id: \.reason) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.reason.icon)
                        .foregroundColor(Theme.accent)
                        .frame(width: 22)
                    Text(item.reason.label)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                        .frame(width: 120, alignment: .leading)
                    GeometryReader { geo in
                        Capsule()
                            .fill(Theme.accent.opacity(0.85))
                            .frame(width: max(6, geo.size.width * CGFloat(item.count) / CGFloat(maxCount)))
                    }
                    .frame(height: 10)
                    Text("\(item.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(16)
        .cardSurface()
    }
}

/// ponytail: tiny bar chart instead of pulling in Charts (iOS 16+).
struct HistogramView: View {
    let buckets: [TimeBucket]
    let maxCount: Int

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(buckets) { bucket in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Theme.accent)
                            .frame(height: barHeight(for: bucket.count, in: geo.size.height - 20))
                        Text(bucket.label)
                            .font(.system(size: 8))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func barHeight(for count: Int, in maxHeight: CGFloat) -> CGFloat {
        guard maxCount > 0 else { return 0 }
        return max(4, maxHeight * CGFloat(count) / CGFloat(maxCount))
    }
}

/// A compact statistic tile.
struct StatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
    }
}
