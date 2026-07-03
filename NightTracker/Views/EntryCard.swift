import SwiftUI

/// Displays a single wakeup: time, reason chips, and optional note.
struct EntryCard: View {
    let entry: WakeEntry
    var prominent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(Format.time.string(from: entry.timestamp))
                    .font(prominent ? .title2.bold() : .headline)
                    .foregroundColor(Theme.accent)
                if !entry.reasons.isEmpty {
                    Text("—")
                        .foregroundColor(Theme.textSecondary)
                    Text(entry.reasons.map(\.label).joined(separator: ", "))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                }
                Spacer()
            }

            if !entry.reasons.isEmpty {
                HStack(spacing: 8) {
                    ForEach(entry.reasons) { reason in
                        HStack(spacing: 5) {
                            Image(systemName: reason.icon)
                                .font(.caption2)
                            Text(reason.label)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundColor(Theme.accentSoft)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.accent.opacity(0.14)))
                    }
                }
            }

            if !entry.note.isEmpty {
                Text("“\(entry.note)”")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(fill: prominent ? Theme.cardElevated : Theme.card)
    }
}
