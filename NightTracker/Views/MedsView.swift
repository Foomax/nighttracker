import SwiftUI

struct MedsView: View {
    @EnvironmentObject private var store: NightStore
    let baby: Baby?

    @State private var selectedKind: MedKind = .ibuprofen
    @State private var customName = ""
    @State private var intervalHours: Double = MedKind.ibuprofen.defaultIntervalHours

    private var doses: [MedDose] {
        (baby?.doses ?? []).sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    logDoseCard
                    if doses.isEmpty {
                        emptyState
                    } else {
                        Text("Active timers")
                            .font(.title3.bold())
                            .foregroundColor(Theme.textPrimary)
                        TimelineView(.periodic(from: Date(), by: 1)) { context in
                            VStack(spacing: 12) {
                                ForEach(doses) { dose in
                                    MedTimerCard(dose: dose, now: context.date) {
                                        delete(dose)
                                    }
                                }
                            }
                        }
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
            Text("Medication")
                .font(.largeTitle.bold())
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var logDoseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Record a dose")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 10) {
                ForEach(MedKind.allCases) { kind in
                    medChip(kind)
                }
            }

            if selectedKind == .other {
                TextField("Medication name", text: $customName)
                    .foregroundColor(Theme.textPrimary)
                    .padding(12)
                    .cardSurface(corner: Theme.cornerSmall, fill: Theme.cardElevated)
            }

            HStack {
                Text("Every")
                    .foregroundColor(Theme.textSecondary)
                Text("\(intervalHours, specifier: "%.0f") h")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 50, alignment: .leading)
                Stepper("", value: $intervalHours, in: 1...12, step: 1)
                    .labelsHidden()
                Spacer()
            }

            Button {
                record()
            } label: {
                Label("Record dose now", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Theme.accent))
            }
            .disabled(baby == nil)
            .opacity(baby == nil ? 0.5 : 1)
        }
        .padding(16)
        .cardSurface()
    }

    private func medChip(_ kind: MedKind) -> some View {
        let isOn = selectedKind == kind
        return Button {
            selectedKind = kind
            intervalHours = kind.defaultIntervalHours
        } label: {
            VStack(spacing: 6) {
                Image(systemName: kind.icon)
                    .font(.title3)
                Text(kind.label)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundColor(isOn ? Color.black : Theme.textPrimary)
            .background(RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                .fill(isOn ? Theme.accent : Theme.cardElevated))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "cross.case")
                .font(.system(size: 32))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("No medication logged")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text("Record a dose to start a safety timer.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .cardSurface()
    }

    private func record() {
        guard let baby else { return }
        let dose = MedDose(
            kind: selectedKind,
            customName: customName.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: Date(),
            intervalHours: intervalHours
        )
        store.addDose(babyID: baby.id, dose: dose)
        customName = ""
    }

    private func delete(_ dose: MedDose) {
        guard let baby else { return }
        store.deleteDose(babyID: baby.id, doseID: dose.id)
    }
}

/// A single medication timer card with a live countdown ring.
struct MedTimerCard: View {
    let dose: MedDose
    let now: Date
    let onDelete: () -> Void

    private var remaining: TimeInterval { dose.secondsRemaining(now: now) }
    private var ready: Bool { dose.isReady(now: now) }
    private var progress: Double {
        let total = dose.intervalHours * 3600
        guard total > 0 else { return 1 }
        return min(1, max(0, 1 - remaining / total))
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Theme.hairline, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ready ? Color.green : Theme.accent,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: dose.kind.icon)
                    .foregroundColor(ready ? Color.green : Theme.accent)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(dose.displayName)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("Taken \(Format.time.string(from: dose.timestamp)) · every \(dose.intervalHours, specifier: "%.0f")h")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                if ready {
                    Text("Ready for next dose")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)
                } else {
                    Text("Next in \(Format.countdown(remaining))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.accent)
                }
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(16)
        .cardSurface()
    }
}
