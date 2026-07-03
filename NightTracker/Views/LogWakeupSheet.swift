import SwiftUI

/// Sheet for logging a new wakeup. Auto-fills the current time (tap to change),
/// lets the parent pick one or more reasons, add a note, save, or bin it.
struct LogWakeupSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var store: NightStore

    let babyID: UUID

    @State private var timestamp = Date()
    @State private var selectedReasons: Set<WakeReason> = []
    @State private var note = ""
    @State private var editingTime = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()),
                           GridItem(.flexible()), GridItem(.flexible())]

    private var baby: Baby? { store.baby(id: babyID) }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        timeCard
                        reasonsSection
                        notesSection
                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Log wakeup — \(baby?.name ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Discard entry")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var timeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text(Format.timeAndDay.string(from: timestamp))
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                Button {
                    withAnimation { editingTime.toggle() }
                } label: {
                    Label(editingTime ? "Done" : "Edit", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.accent)
                }
            }
            if editingTime {
                DatePicker("", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .accentColor(Theme.accent)
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var reasonsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Why did they wake?")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(WakeReason.allCases) { reason in
                    reasonTile(reason)
                }
            }
        }
    }

    private func reasonTile(_ reason: WakeReason) -> some View {
        let isOn = selectedReasons.contains(reason)
        return Button {
            withAnimation(.easeOut(duration: 0.12)) {
                if isOn { selectedReasons.remove(reason) } else { selectedReasons.insert(reason) }
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: reason.icon)
                    .font(.title3)
                Text(reason.label)
                    .font(.caption2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 78)
            .foregroundColor(isOn ? Color.black : Theme.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                    .fill(isOn ? Theme.accent : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                    .strokeBorder(isOn ? Color.clear : Theme.hairline, lineWidth: 1)
            )
        }
    }

    private var notesSection: some View {
        TextField("Add notes here…", text: $note)
            .foregroundColor(Theme.textPrimary)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .cardSurface()
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Save entry")
                .font(.headline)
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Theme.accent))
        }
    }

    private func save() {
        let entry = WakeEntry(
            timestamp: timestamp,
            reasons: WakeReason.allCases.filter { selectedReasons.contains($0) },
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.addEntry(babyID: babyID, entry: entry)
        presentationMode.wrappedValue.dismiss()
    }
}
