import SwiftUI

struct DutyBoardView: View {
    @EnvironmentObject private var store: LedgerStore
    @State private var query: String = ""
    @State private var showEditor = false
    @State private var editorDuty: BudgetDuty?
    @State private var pendingDelete: BudgetDuty?
    @State private var lens: DutyLens = .all

    private var filtered: [BudgetDuty] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let searched: [BudgetDuty]
        if needle.isEmpty {
            searched = store.duties
        } else {
            searched = store.duties.filter { duty in
                duty.title.lowercased().contains(needle) || duty.category.lowercased().contains(needle)
            }
        }
        switch lens {
        case .all:
            return searched
        case .open:
            return searched.filter { !$0.isSettled }
        case .overdue:
            return searched.filter { isOverdue($0) }
        case .settled:
            return searched.filter { $0.isSettled }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GoldBanner(imageName: "BannerTasks")

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Palette.primary)
                    TextField("Search duties", text: $query)
                        .foregroundColor(Palette.primary)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Button {
                        editorDuty = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Palette.background)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle().fill(
                                    LinearGradient(
                                        colors: [Palette.primary, Palette.accent],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            )
                            .shadow(color: Palette.primary.opacity(0.35), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Palette.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Palette.primary, lineWidth: 1)
                        )
                )

                lensRow
                templateRow

                if store.lastTaskUpdate != Date.distantPast, !store.duties.isEmpty {
                    Text("Ledger touched \(Self.stamp.string(from: store.lastTaskUpdate))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Palette.accent.opacity(0.85))
                }

                if store.duties.isEmpty {
                    emptyBoard
                } else if filtered.isEmpty {
                    LedgerPlate {
                        Text("No duties match that filter.")
                            .font(.system(.callout, design: .serif))
                            .foregroundColor(Palette.primary)
                    }
                } else {
                    dutySections
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
        .sheet(isPresented: $showEditor) {
            DutyEditorSheet(existing: editorDuty)
                .environmentObject(store)
        }
        .alert("Remove Duty", isPresented: deleteAlertBinding) {
            Button("Delete", role: .destructive) {
                if let pendingDelete = pendingDelete {
                    store.deleteDuty(pendingDelete)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("This duty will be removed from the ledger.")
        }
        .onReceive(NotificationCenter.default.publisher(for: LedgerStore.dataResetName)) { _ in
            query = ""
            showEditor = false
            pendingDelete = nil
            lens = .all
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private var emptyBoard: some View {
        LedgerPlate {
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Palette.primary)
                Text("No Tasks Yet! Tap '+' to add your first financial task")
                    .font(.system(.callout, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Palette.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private var dutySections: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(DutyPriority.allCases) { bucket in
                let open = filtered.filter { $0.priority == bucket && !$0.isSettled }
                if !open.isEmpty {
                    sectionHeader(bucket.ledgerTitle)
                    ForEach(open) { duty in
                        dutyRow(duty)
                    }
                }
            }

            let settled = filtered.filter { $0.isSettled }
            if !settled.isEmpty {
                sectionHeader("Settled")
                ForEach(settled) { duty in
                    dutyRow(duty)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .bold, design: .serif))
            .tracking(1.2)
            .foregroundColor(Palette.accent)
    }

    private func dutyRow(_ duty: BudgetDuty) -> some View {
        LedgerPlate {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    store.toggleDuty(duty)
                } label: {
                    SphereRing(progress: duty.isSettled ? 1 : 0.12, size: 42, lineWidth: 4) {
                        Image(systemName: duty.isSettled ? "checkmark" : "circle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Palette.primary)
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(duty.title)
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(Palette.primary)
                        .strikethrough(duty.isSettled, color: Palette.accent)
                    Text(duty.category)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Palette.accent)
                    Text("Due \(Self.day.string(from: duty.dueDate))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(isOverdue(duty) ? Palette.accent : Palette.primary.opacity(0.8))
                    if isOverdue(duty) {
                        Text("OVERDUE")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .tracking(1.0)
                            .foregroundColor(Palette.accent)
                    }
                    if let linked = store.expense(for: duty.linkedExpenseID) {
                        MoneyText(amount: linked.amount, size: .system(size: 12, design: .monospaced))
                    }
                }

                Spacer(minLength: 0)

                VStack(spacing: 8) {
                    Button {
                        editorDuty = duty
                        showEditor = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(Palette.primary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        pendingDelete = duty
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(Palette.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var lensRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(DutyLens.allCases) { item in
                    Button {
                        lens = item
                    } label: {
                        Text(item.title)
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundColor(lens == item ? Palette.background : Palette.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(lensChip(selected: lens == item))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var templateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TEMPLATES")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .tracking(1.2)
                .foregroundColor(Palette.accent)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(store.availableDutyTemplates) { item in
                        Button {
                            store.applyDutyTemplate(item)
                        } label: {
                            Text(item.title)
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundColor(Palette.background)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(
                                            colors: [Palette.primary, Palette.accent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func lensChip(selected: Bool) -> some View {
        if selected {
            Capsule().fill(
                LinearGradient(
                    colors: [Palette.primary, Palette.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            Capsule()
                .fill(Palette.surface)
                .overlay(Capsule().stroke(Palette.primary, lineWidth: 1))
        }
    }

    private func isOverdue(_ duty: BudgetDuty) -> Bool {
        !duty.isSettled && duty.dueDate < Calendar.current.startOfDay(for: Date())
    }

    private static let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private enum DutyLens: String, CaseIterable, Identifiable {
    case all
    case open
    case overdue
    case settled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .open: return "Open"
        case .overdue: return "Overdue"
        case .settled: return "Settled"
        }
    }
}
