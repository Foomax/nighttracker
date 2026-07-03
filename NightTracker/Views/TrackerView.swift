import SwiftUI

struct TrackerView: View {
    @EnvironmentObject private var store: NightStore
    @Binding var selectedBabyID: UUID?

    @State private var showLogSheet = false
    @State private var showAddProfile = false
    @State private var renameTarget: Baby?
    @State private var nameField = ""

    private var babies: [Baby] { store.sortedBabies }

    private var selectedBaby: Baby? {
        store.baby(id: selectedBabyID)
    }

    private var sortedEntries: [WakeEntry] {
        (selectedBaby?.entries ?? []).sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    profilePicker
                    if let insight = insightText {
                        insightCard(insight)
                    }
                    lastWakeupSection
                    tonightLogSection
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            newEntryButton
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "openLog") { showLogSheet = true }
            if selectedBabyID == nil { selectedBabyID = babies.first?.id }
        }
        .sheet(isPresented: $showLogSheet) {
            if let baby = selectedBaby {
                LogWakeupSheet(babyID: baby.id)
            }
        }
        .sheet(isPresented: $showAddProfile) {
            NameInputSheet(title: "New profile", message: "Add a baby or parent profile to track.", name: $nameField) {
                createProfile()
            }
        }
        .sheet(item: $renameTarget) { baby in
            NameInputSheet(title: "Rename profile", message: nil, name: $nameField) {
                commitRename(baby)
            }
            .onAppear { nameField = baby.name }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Good night")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Text("Night Tracker")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            Button {
                nameField = ""
                showAddProfile = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundColor(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.accent.opacity(0.18)))
            }
            .accessibilityLabel("Add profile")
        }
    }

    private var profilePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(babies) { baby in
                    profileChip(baby)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func profileChip(_ baby: Baby) -> some View {
        let isSelected = baby.id == (selectedBabyID ?? selectedBaby?.id)
        return Menu {
            Button("Rename") {
                renameTarget = baby
                nameField = baby.name
            }
            Button("Delete", role: .destructive) { deleteProfile(baby) }
        } label: {
            Text(baby.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? Color.black : Theme.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(Capsule().fill(isSelected ? Theme.accent : Theme.card))
                .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: isSelected ? 0 : 1))
        } primaryAction: {
            selectedBabyID = baby.id
        }
    }

    private var insightText: String? {
        guard let baby = selectedBaby else { return nil }
        return Analytics.insight(for: baby.name, entries: baby.entries)
    }

    private func insightCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(Theme.accent)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.accent.opacity(0.16)))
            Text(text)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.9))
            Spacer(minLength: 0)
        }
        .padding(16)
        .cardSurface()
    }

    private var lastWakeupSection: some View {
        Group {
            if let last = sortedEntries.first {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last wakeup")
                        .font(.title3.bold())
                        .foregroundColor(Theme.textPrimary)
                    EntryCard(entry: last, prominent: true)
                }
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 34))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("No wakeups logged yet")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text("Tap “New entry” when \(selectedBaby?.name ?? "your baby") wakes up tonight.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 16)
        .cardSurface()
    }

    private var tonightLog: [WakeEntry] {
        NightWindow.entriesTonight(sortedEntries)
    }

    private var tonightLogSection: some View {
        Group {
            if tonightLog.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tonight's log")
                        .font(.title3.bold())
                        .foregroundColor(Theme.textPrimary)
                    ForEach(tonightLog.dropFirst()) { entry in
                        EntryCard(entry: entry, prominent: false)
                    }
                }
            }
        }
    }

    private var newEntryButton: some View {
        Button {
            showLogSheet = true
        } label: {
            Label("New entry", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Theme.accent))
                .shadow(color: Theme.accent.opacity(0.4), radius: 16, y: 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .disabled(selectedBaby == nil)
        .opacity(selectedBaby == nil ? 0.5 : 1)
    }

    private func createProfile() {
        let trimmed = nameField.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let baby = store.addBaby(name: trimmed)
        selectedBabyID = baby.id
        nameField = ""
        showAddProfile = false
    }

    private func commitRename(_ baby: Baby) {
        let trimmed = nameField.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { store.renameBaby(id: baby.id, name: trimmed) }
        renameTarget = nil
        nameField = ""
    }

    private func deleteProfile(_ baby: Baby) {
        let wasSelected = baby.id == selectedBaby?.id
        store.deleteBaby(id: baby.id)
        if wasSelected { selectedBabyID = store.sortedBabies.first?.id }
    }
}

/// ponytail: iOS 15 has no TextField-in-alert; a tiny sheet is the smallest fix.
struct NameInputSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    let title: String
    let message: String?
    @Binding var name: String
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                TextField("Name", text: $name)
                    .foregroundColor(Theme.textPrimary)
                    .padding(12)
                    .cardSurface(corner: Theme.cornerSmall, fill: Theme.cardElevated)
                Spacer()
            }
            .padding(20)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
