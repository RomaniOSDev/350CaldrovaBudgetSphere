import SwiftUI

struct SpendInsightsView: View {
    @EnvironmentObject private var store: LedgerStore
    @State private var showPriorMonths = false
    @State private var showEditor = false
    @State private var editorExpense: ExpenseEntry?
    @State private var pendingDelete: ExpenseEntry?
    @State private var budgetDrafts: [String: String] = [:]
    @State private var expenseQuery: String = ""
    @State private var budgetCommitWork: DispatchWorkItem?
    @State private var showRecurring = false
    @State private var editorRecurrence: RecurringCharge?
    @State private var showSavings = false
    @State private var editorGoal: SavingsGoal?
    @State private var pendingRecurrence: RecurringCharge?
    @State private var pendingGoal: SavingsGoal?
    @State private var copyNotice: String = ""

    private var monthAnchor: Date { Date() }

    private var monthExpenses: [ExpenseEntry] {
        let items = store.expenses(inMonthOf: monthAnchor).sorted { $0.date > $1.date }
        let needle = expenseQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return items }
        return items.filter { item in
            item.category.lowercased().contains(needle)
                || item.note.lowercased().contains(needle)
                || item.payee.lowercased().contains(needle)
                || MoneyText.format(item.amount).lowercased().contains(needle)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GoldBanner(imageName: "BannerChart")

                HStack(spacing: 8) {
                    historyToggle
                    Spacer()
                    if !store.expenses.isEmpty {
                        Button {
                            store.repeatLatestExpense()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Palette.primary)
                                .frame(width: 34, height: 34)
                                .background(Circle().stroke(Palette.primary, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Repeat last expense")
                    }
                    Button {
                        editorExpense = nil
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

                sessionInsight

                if !showPriorMonths {
                    envelopePlate
                    searchField
                    recurringSection
                    savingsSection
                }

                if store.expenses.isEmpty {
                    emptyBoard
                } else if showPriorMonths {
                    priorHistory
                } else {
                    categoryBars
                    budgetEditors
                    if monthExpenses.isEmpty {
                        LedgerPlate {
                            Text(expenseQuery.isEmpty
                                 ? "No postings in this month yet."
                                 : "No postings match that search.")
                                .font(.system(.callout, design: .serif))
                                .foregroundColor(Palette.primary)
                        }
                    } else {
                        expenseList(monthExpenses)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
        .onDisappear {
            budgetCommitWork?.cancel()
            flushBudgets()
        }
        .sheet(isPresented: $showEditor) {
            ExpenseEditorSheet(existing: editorExpense)
                .environmentObject(store)
        }
        .sheet(isPresented: $showRecurring) {
            RecurringEditorSheet(existing: editorRecurrence)
                .environmentObject(store)
        }
        .sheet(isPresented: $showSavings) {
            SavingsEditorSheet(existing: editorGoal)
                .environmentObject(store)
        }
        .alert("Remove Expense", isPresented: deleteAlertBinding) {
            Button("Delete", role: .destructive) {
                if let pendingDelete = pendingDelete {
                    store.deleteExpense(pendingDelete)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("This posting will leave the ledger.")
        }
        .onAppear { syncBudgetDrafts() }
        .onReceive(NotificationCenter.default.publisher(for: LedgerStore.dataResetName)) { _ in
            showPriorMonths = false
            showEditor = false
            expenseQuery = ""
            budgetDrafts = [:]
            copyNotice = ""
            showRecurring = false
            showSavings = false
            showEditor = false
        }
        .alert("Remove Standing Charge", isPresented: recurrenceAlertBinding) {
            Button("Delete", role: .destructive) {
                if let pendingRecurrence {
                    store.deleteRecurrence(pendingRecurrence)
                }
                pendingRecurrence = nil
            }
            Button("Cancel", role: .cancel) { pendingRecurrence = nil }
        }
        .alert("Remove Goal", isPresented: goalAlertBinding) {
            Button("Delete", role: .destructive) {
                if let pendingGoal {
                    store.deleteSavingsGoal(pendingGoal)
                }
                pendingGoal = nil
            }
            Button("Cancel", role: .cancel) { pendingGoal = nil }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private var recurrenceAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingRecurrence != nil },
            set: { if !$0 { pendingRecurrence = nil } }
        )
    }

    private var goalAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingGoal != nil },
            set: { if !$0 { pendingGoal = nil } }
        )
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Palette.primary)
            TextField("Search postings", text: $expenseQuery)
                .foregroundColor(Palette.primary)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
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
    }

    private var envelopePlate: some View {
        let snap = store.envelope(from: monthAnchor)
        return LedgerPlate {
            VStack(alignment: .leading, spacing: 10) {
                Text("WEEKLY ENVELOPE")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                if snap.hasCaps {
                    HStack(alignment: .top, spacing: 10) {
                        envelopeChip(
                            title: "Today",
                            value: snap.leftToday >= 0
                                ? "left \(MoneyText.format(snap.leftToday))"
                                : "over \(MoneyText.format(-snap.leftToday))",
                            detail: "limit \(MoneyText.format(snap.dailyLimit))"
                        )
                        envelopeChip(
                            title: "This week",
                            value: MoneyText.format(snap.thisWeek),
                            detail: snap.leftThisWeek >= 0
                                ? "left \(MoneyText.format(snap.leftThisWeek))"
                                : "over \(MoneyText.format(-snap.leftThisWeek))"
                        )
                    }
                    Text("Last week \(MoneyText.format(snap.lastWeek)) · \(snap.daysLeftInMonth) days left in month")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(Palette.primary.opacity(0.75))
                } else {
                    Text("Set monthly caps to unlock a daily limit and leftover for today.")
                        .font(.system(.callout, design: .serif))
                        .foregroundColor(Palette.primary)
                    HStack {
                        Text("This week \(MoneyText.format(snap.thisWeek))")
                        Spacer()
                        Text("Last week \(MoneyText.format(snap.lastWeek))")
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Palette.primary)
                }
            }
        }
    }

    private func envelopeChip(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .serif))
                .foregroundColor(Palette.accent)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Palette.primary)
            Text(detail)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Palette.primary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("STANDING CHARGES")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                Spacer()
                Button {
                    editorRecurrence = nil
                    showRecurring = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
            }
            if store.recurrences.isEmpty {
                Text("Rent and subscriptions post on their day each month.")
                    .font(.system(.caption, design: .serif))
                    .foregroundColor(Palette.primary.opacity(0.8))
            } else {
                ForEach(store.recurrences) { item in
                    LedgerPlate {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                                    .foregroundColor(Palette.primary)
                                Text("Day \(item.dayOfMonth) · \(item.category)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Palette.accent)
                                if !item.payee.isEmpty {
                                    Text(item.payee)
                                        .font(.caption)
                                        .foregroundColor(Palette.primary.opacity(0.75))
                                }
                            }
                            Spacer()
                            MoneyText(amount: item.amount, size: .system(.subheadline, design: .monospaced))
                            Button {
                                editorRecurrence = item
                                showRecurring = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(Palette.primary)
                            }
                            .buttonStyle(.plain)
                            Button {
                                pendingRecurrence = item
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(Palette.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var savingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SAVINGS RINGS")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                Spacer()
                Button {
                    editorGoal = nil
                    showSavings = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
            }
            if store.savingsGoals.isEmpty {
                Text("Separate from monthly caps — emergency fund, travel, a buffer.")
                    .font(.system(.caption, design: .serif))
                    .foregroundColor(Palette.primary.opacity(0.8))
            } else {
                ForEach(store.savingsGoals) { goal in
                    LedgerPlate {
                        HStack(spacing: 12) {
                            SphereRing(progress: goal.progress, size: 56, lineWidth: 5) {
                                Text("\(Int((goal.progress * 100).rounded()))%")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Palette.primary)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.name)
                                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                                    .foregroundColor(Palette.primary)
                                Text("\(MoneyText.format(goal.saved)) of \(MoneyText.format(goal.target))")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(Palette.primary.opacity(0.75))
                            }
                            Spacer(minLength: 0)
                            Button {
                                editorGoal = goal
                                showSavings = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(Palette.primary)
                            }
                            .buttonStyle(.plain)
                            Button {
                                pendingGoal = goal
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(Palette.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var historyToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showPriorMonths.toggle()
            }
        } label: {
            Text(showPriorMonths ? "This Month" : "Prior Months")
                .font(.system(.caption, design: .serif).weight(.bold))
                .foregroundColor(Palette.background)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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

    private var emptyBoard: some View {
        LedgerPlate {
            VStack(spacing: 10) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Palette.primary)
                Text("No expenses logged yet")
                    .font(.system(.callout, design: .serif))
                    .foregroundColor(Palette.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private var sessionInsight: some View {
        let count = store.sessionsThisMonth(from: monthAnchor)
        let goal = 20.0
        return LedgerPlate {
            HStack(spacing: 14) {
                SphereRing(progress: min(1, Double(count) / goal), size: 62, lineWidth: 6) {
                    Text("\(count)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Palette.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus sessions this month")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(Palette.primary)
                    Text("Closed cycles land on this ledger.")
                        .font(.caption)
                        .foregroundColor(Palette.primary.opacity(0.75))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var categoryBars: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MONTH BY CATEGORY")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .tracking(1.2)
                .foregroundColor(Palette.accent)

            ForEach(store.categories, id: \.self) { name in
                let spent = store.spent(in: name, monthOf: monthAnchor)
                let cap = store.monthlyBudget[name] ?? 0
                let progress = cap > 0 ? min(1, spent / cap) : 0
                LedgerPlate {
                    HStack(spacing: 12) {
                        SphereRing(progress: progress, size: 52, lineWidth: 5) {
                            Text(percentLabel(spent: spent, cap: cap))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Palette.primary)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(name)
                                .font(.system(.subheadline, design: .serif).weight(.semibold))
                                .foregroundColor(Palette.primary)
                            HStack {
                                MoneyText(amount: spent, size: .system(size: 13, design: .monospaced))
                                if cap > 0 {
                                    Text("of \(MoneyText.format(cap))")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(Palette.primary.opacity(0.7))
                                }
                                Spacer(minLength: 0)
                                if let leftover = store.leftover(in: name, monthOf: monthAnchor) {
                                    Text(leftover >= 0
                                         ? "left \(MoneyText.format(leftover))"
                                         : "over \(MoneyText.format(-leftover))")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(leftover >= 0 ? Palette.primary : Palette.accent)
                                }
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Palette.background)
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Palette.primary, Palette.accent],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(progress))
                                }
                            }
                            .frame(height: 7)
                        }
                    }
                }
            }
        }
    }

    private var budgetEditors: some View {
        LedgerPlate {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("MONTHLY CAPS")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .tracking(1.2)
                        .foregroundColor(Palette.accent)
                    Spacer()
                    Button {
                        if store.copyPriorMonthCaps() {
                            syncBudgetDrafts()
                            copyNotice = "Copied last month's caps."
                        } else {
                            copyNotice = "No prior month caps stored yet."
                        }
                    } label: {
                        Text("Copy last month")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundColor(Palette.primary)
                    }
                    .buttonStyle(.plain)
                }
                if !copyNotice.isEmpty {
                    Text(copyNotice)
                        .font(.caption)
                        .foregroundColor(Palette.accent)
                }
                ForEach(store.categories, id: \.self) { name in
                    HStack {
                        Text(name)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundColor(Palette.primary)
                        Spacer()
                        TextField("0", text: budgetBinding(name))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(Palette.primary)
                            .frame(width: 96)
                            .onSubmit { flushBudgets() }
                    }
                }
            }
        }
    }

    private var priorHistory: some View {
        let groups = store.priorMonthGroups(from: monthAnchor)
        return VStack(alignment: .leading, spacing: 12) {
            if groups.isEmpty {
                LedgerPlate {
                    Text("No earlier months on the ledger.")
                        .font(.system(.callout, design: .serif))
                        .foregroundColor(Palette.primary)
                }
            } else {
                ForEach(groups, id: \.month) { group in
                    Text(Self.month.string(from: group.month).uppercased())
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .tracking(1.1)
                        .foregroundColor(Palette.accent)
                    expenseList(group.items)
                }
            }
        }
    }

    private func expenseList(_ items: [ExpenseEntry]) -> some View {
        VStack(spacing: 10) {
            ForEach(items) { item in
                LedgerPlate {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.category)
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Palette.primary)
                            if !item.payee.isEmpty {
                                Text(item.payee)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Palette.primary.opacity(0.85))
                            }
                            HStack(spacing: 6) {
                                Text(Self.day.string(from: item.date))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(Palette.accent)
                                if item.splitGroupID != nil {
                                    Text("SPLIT")
                                        .font(.system(size: 9, weight: .bold, design: .serif))
                                        .foregroundColor(Palette.background)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Palette.accent))
                                }
                            }
                            if !item.note.isEmpty {
                                Text(item.note)
                                    .font(.caption)
                                    .foregroundColor(Palette.primary.opacity(0.75))
                            }
                        }
                        Spacer(minLength: 0)
                        VStack(alignment: .trailing, spacing: 8) {
                            MoneyText(amount: item.amount, size: .system(.headline, design: .monospaced))
                            HStack(spacing: 10) {
                                Button {
                                    editorExpense = item
                                    showEditor = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(Palette.primary)
                                }
                                .buttonStyle(.plain)
                                Button {
                                    pendingDelete = item
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(Palette.accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func budgetBinding(_ name: String) -> Binding<String> {
        Binding(
            get: { budgetDrafts[name] ?? "" },
            set: { newValue in
                budgetDrafts[name] = newValue
                scheduleBudgetCommit()
            }
        )
    }

    private func scheduleBudgetCommit() {
        budgetCommitWork?.cancel()
        let work = DispatchWorkItem { flushBudgets() }
        budgetCommitWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: work)
    }

    private func syncBudgetDrafts() {
        var next: [String: String] = [:]
        for name in store.categories {
            if let value = store.monthlyBudget[name], value > 0 {
                next[name] = String(format: "%.2f", value)
            } else {
                next[name] = budgetDrafts[name] ?? ""
            }
        }
        budgetDrafts = next
    }

    private func flushBudgets() {
        for name in store.categories {
            let trimmed = (budgetDrafts[name] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let next: Double
            if trimmed.isEmpty {
                next = 0
            } else if let value = MoneyText.parse(trimmed) {
                next = value
            } else {
                continue
            }
            let current = store.monthlyBudget[name] ?? 0
            if abs(current - next) > 0.0001 {
                store.setMonthlyBudget(next, for: name)
            }
        }
    }

    private func percentLabel(spent: Double, cap: Double) -> String {
        guard cap > 0 else { return "—" }
        let pct = min(999, Int((spent / cap * 100).rounded()))
        return "\(pct)%"
    }

    private static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let month: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}
