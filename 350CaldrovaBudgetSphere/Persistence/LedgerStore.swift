import Combine
import SwiftUI
import UIKit

final class LedgerStore: ObservableObject {
    static let dataResetName = Notification.Name("dataReset")

    static let defaultCategories = [
        "Groceries", "Utilities", "Transit", "Dining", "Rent", "Other"
    ]

    @Published var duties: [BudgetDuty] = []
    @Published var expenses: [ExpenseEntry] = []
    @Published var categories: [String] = LedgerStore.defaultCategories
    @Published var monthlyBudget: [String: Double] = [:]
    @Published var focusDurationMin: Int = 25
    @Published var breakDurationMin: Int = 5
    @Published var sessionHistory: [Date] = []
    @Published var completedSessionsToday: Int = 0
    @Published var lastTaskUpdate: Date = Date()
    @Published var defaultCategory: String = "Groceries"
    @Published var timerRunning: Bool = false
    @Published var timerEndsAt: Date?
    @Published var isBreak: Bool = false
    @Published var remainingSnapshot: TimeInterval = 25 * 60
    @Published var durationNotice: String = ""
    @Published var showWellDone: Bool = false
    @Published var recurrences: [RecurringCharge] = []
    @Published var savingsGoals: [SavingsGoal] = []
    @Published var dutyTemplates: [DutyTemplate] = []
    @Published var monthlyBudgetHistory: [String: [String: Double]] = [:]
    @Published var hapticOnComplete: Bool = true
    @Published var soundOnComplete: Bool = true

    private let defaults = UserDefaults.standard
    private var ticker: Timer?
    private var pausedByScene = false
    private var sessionsDayKey: String = ""
    private var lastPersistAt = Date.distantPast
    private var wellDoneWork: DispatchWorkItem?

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private enum Keys {
        static let duties = "ledger.duties"
        static let expenses = "ledger.expenses"
        static let categories = "ledger.categories"
        static let monthlyBudget = "ledger.monthlyBudget"
        static let focusDurationMin = "ledger.focusDurationMin"
        static let breakDurationMin = "ledger.breakDurationMin"
        static let sessionHistory = "ledger.sessionHistory"
        static let completedSessionsToday = "ledger.completedSessionsToday"
        static let sessionsDayKey = "ledger.sessionsDayKey"
        static let lastTaskUpdate = "ledger.lastTaskUpdate"
        static let defaultCategory = "ledger.defaultCategory"
        static let timerRunning = "ledger.timerRunning"
        static let timerEndsAt = "ledger.timerEndsAt"
        static let isBreak = "ledger.isBreak"
        static let remainingSnapshot = "ledger.remainingSnapshot"
        static let pausedByScene = "ledger.pausedByScene"
        static let recurrences = "ledger.recurrences"
        static let savingsGoals = "ledger.savingsGoals"
        static let dutyTemplates = "ledger.dutyTemplates"
        static let monthlyBudgetHistory = "ledger.monthlyBudgetHistory"
        static let hapticOnComplete = "ledger.hapticOnComplete"
        static let soundOnComplete = "ledger.soundOnComplete"
    }

    static let stockDutyTemplates: [DutyTemplate] = [
        DutyTemplate(
            id: UUID(uuidString: "AAAAAAAA-0001-4000-8000-000000000001") ?? UUID(),
            title: "Pay bills",
            category: "Utilities",
            priority: .high
        ),
        DutyTemplate(
            id: UUID(uuidString: "AAAAAAAA-0001-4000-8000-000000000002") ?? UUID(),
            title: "Reconcile card",
            category: "Other",
            priority: .monthReview
        ),
        DutyTemplate(
            id: UUID(uuidString: "AAAAAAAA-0001-4000-8000-000000000003") ?? UUID(),
            title: "Review subscriptions",
            category: "Utilities",
            priority: .normal
        ),
        DutyTemplate(
            id: UUID(uuidString: "AAAAAAAA-0001-4000-8000-000000000004") ?? UUID(),
            title: "Restock groceries",
            category: "Groceries",
            priority: .normal
        )
    ]

    static var allStoreKeys: [String] {
        [
            Keys.duties, Keys.expenses, Keys.categories, Keys.monthlyBudget,
            Keys.focusDurationMin, Keys.breakDurationMin, Keys.sessionHistory,
            Keys.completedSessionsToday, Keys.sessionsDayKey, Keys.lastTaskUpdate,
            Keys.defaultCategory, Keys.timerRunning, Keys.timerEndsAt,
            Keys.isBreak, Keys.remainingSnapshot, Keys.pausedByScene,
            Keys.recurrences, Keys.savingsGoals, Keys.dutyTemplates,
            Keys.monthlyBudgetHistory, Keys.hapticOnComplete, Keys.soundOnComplete
        ]
    }

    init() {
        loadAll()
        rollDailySessionsIfNeeded()
        sanitizeDurations()
        reconcileTimerOnLaunch()
        snapshotCapsForCurrentMonth()
        postDueRecurrences()
        installTicker()
    }

    deinit {
        ticker?.invalidate()
        ticker = nil
        wellDoneWork?.cancel()
    }

    func remaining(at date: Date = Date()) -> TimeInterval {
        if timerRunning, let end = timerEndsAt {
            return max(0, end.timeIntervalSince(date))
        }
        return max(0, remainingSnapshot)
    }

    func progress(at date: Date = Date()) -> Double {
        let total = currentCycleSeconds()
        guard total > 0 else { return 0 }
        let left = remaining(at: date)
        return min(1, max(0, 1 - (left / total)))
    }

    func currentCycleSeconds() -> TimeInterval {
        let minutes = isBreak ? breakDurationMin : focusDurationMin
        return Double(max(1, minutes) * 60)
    }

    func armIdleCycleIfNeeded() {
        if remaining() <= 0 {
            remainingSnapshot = currentCycleSeconds()
        }
    }

    func startTimer() {
        armIdleCycleIfNeeded()
        let left = remaining()
        guard left > 0 else { return }
        timerEndsAt = Date().addingTimeInterval(left)
        timerRunning = true
        pausedByScene = false
        persist()
        installTicker()
    }

    func pauseTimer() {
        remainingSnapshot = remaining()
        timerRunning = false
        timerEndsAt = nil
        pausedByScene = false
        persist()
        ticker?.invalidate()
        ticker = nil
    }

    func resumeTimer() {
        guard remainingSnapshot > 0 else { return }
        startTimer()
    }

    func pauseTimerForBackground() {
        guard timerRunning else { return }
        remainingSnapshot = remaining()
        timerRunning = false
        timerEndsAt = nil
        pausedByScene = true
        persist()
        ticker?.invalidate()
        ticker = nil
    }

    func resumeTimerFromForeground() {
        rollDailySessionsIfNeeded()
        if remainingSnapshot <= 0, pausedByScene {
            pausedByScene = false
            finishCycle()
            return
        }
        if pausedByScene, remainingSnapshot > 0 {
            pausedByScene = false
            startTimer()
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            resumeTimerFromForeground()
            postDueRecurrences()
        case .inactive, .background:
            pauseTimerForBackground()
        @unknown default:
            pauseTimerForBackground()
        }
    }

    func setFocusDuration(_ minutes: Int) {
        let clamped = min(60, max(15, minutes))
        if clamped != minutes {
            durationNotice = "Focus length must stay between 15 and 60 minutes."
        } else if durationNotice.contains("Focus length") {
            durationNotice = ""
        }
        focusDurationMin = clamped
        if !timerRunning && !isBreak {
            remainingSnapshot = Double(clamped * 60)
        }
        persist()
    }

    func setBreakDuration(_ minutes: Int) {
        let clamped = min(20, max(5, minutes))
        if clamped != minutes {
            durationNotice = "Break length must stay between 5 and 20 minutes."
        } else if durationNotice.contains("Break length") {
            durationNotice = ""
        }
        breakDurationMin = clamped
        if !timerRunning && isBreak {
            remainingSnapshot = Double(clamped * 60)
        }
        persist()
    }

    func addDuty(_ duty: BudgetDuty) {
        duties.insert(duty, at: 0)
        lastTaskUpdate = Date()
        persist()
    }

    func updateDuty(_ duty: BudgetDuty) {
        guard let index = duties.firstIndex(where: { $0.id == duty.id }) else { return }
        duties[index] = duty
        lastTaskUpdate = Date()
        persist()
    }

    func deleteDuty(_ duty: BudgetDuty) {
        duties.removeAll { $0.id == duty.id }
        lastTaskUpdate = Date()
        persist()
    }

    func toggleDuty(_ duty: BudgetDuty) {
        guard let index = duties.firstIndex(where: { $0.id == duty.id }) else { return }
        if duties[index].completedAt == nil {
            duties[index].completedAt = Date()
        } else {
            duties[index].completedAt = nil
        }
        lastTaskUpdate = Date()
        persist()
    }

    func addExpense(_ entry: ExpenseEntry, createFollowUp: Bool = true) {
        expenses.insert(entry, at: 0)
        if createFollowUp {
            let review = BudgetDuty(
                title: "Review \(entry.category) spend",
                category: entry.category,
                priority: .monthReview,
                dueDate: Self.endOfMonth(from: entry.date),
                linkedExpenseID: entry.id
            )
            duties.insert(review, at: 0)
            lastTaskUpdate = Date()
        }
        persist()
    }

    func updateExpense(_ entry: ExpenseEntry) {
        guard let index = expenses.firstIndex(where: { $0.id == entry.id }) else { return }
        expenses[index] = entry
        persist()
    }

    func deleteExpense(_ entry: ExpenseEntry) {
        expenses.removeAll { $0.id == entry.id }
        persist()
    }

    func expense(for id: UUID?) -> ExpenseEntry? {
        guard let id = id else { return nil }
        return expenses.first { $0.id == id }
    }

    func setMonthlyBudget(_ amount: Double, for category: String) {
        let value = amount.isFinite ? max(0, amount) : 0
        monthlyBudget[category] = value
        snapshotCapsForCurrentMonth()
        persist()
    }

    func copyPriorMonthCaps() -> Bool {
        snapshotCapsForCurrentMonth()
        guard let prior = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else { return false }
        let key = Self.monthKey(prior)
        guard let caps = monthlyBudgetHistory[key], caps.contains(where: { $0.value > 0 }) else {
            return false
        }
        monthlyBudget = caps
        snapshotCapsForCurrentMonth()
        persist()
        return true
    }

    var availableDutyTemplates: [DutyTemplate] {
        var seen = Set<UUID>()
        var combined: [DutyTemplate] = []
        for item in LedgerStore.stockDutyTemplates + dutyTemplates {
            if seen.insert(item.id).inserted {
                combined.append(item)
            }
        }
        return combined
    }

    func applyDutyTemplate(_ template: DutyTemplate) {
        let category = categories.contains(template.category) ? template.category : (defaultCategory)
        let due: Date
        switch template.priority {
        case .high:
            due = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        case .monthReview:
            due = Self.endOfMonth(from: Date())
        case .normal:
            due = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        }
        addDuty(
            BudgetDuty(
                title: template.title,
                category: category,
                priority: template.priority,
                dueDate: due
            )
        )
    }

    func saveDutyTemplate(title: String, category: String, priority: DutyPriority) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = DutyTemplate(title: trimmed, category: category, priority: priority)
        dutyTemplates.removeAll { $0.title.caseInsensitiveCompare(trimmed) == .orderedSame }
        dutyTemplates.insert(item, at: 0)
        persist()
    }

    func addRecurrence(_ item: RecurringCharge) {
        recurrences.insert(item, at: 0)
        persist()
        postDueRecurrences()
    }

    func updateRecurrence(_ item: RecurringCharge) {
        guard let index = recurrences.firstIndex(where: { $0.id == item.id }) else { return }
        recurrences[index] = item
        persist()
        postDueRecurrences()
    }

    func deleteRecurrence(_ item: RecurringCharge) {
        recurrences.removeAll { $0.id == item.id }
        persist()
    }

    func addSavingsGoal(_ goal: SavingsGoal) {
        savingsGoals.insert(goal, at: 0)
        persist()
    }

    func updateSavingsGoal(_ goal: SavingsGoal) {
        guard let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        savingsGoals[index] = goal
        persist()
    }

    func deleteSavingsGoal(_ goal: SavingsGoal) {
        savingsGoals.removeAll { $0.id == goal.id }
        persist()
    }

    func adjustSavings(_ goal: SavingsGoal, delta: Double) {
        guard let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        let next = savingsGoals[index].saved + delta
        savingsGoals[index].saved = next.isFinite ? max(0, next) : 0
        persist()
    }

    func setHapticOnComplete(_ enabled: Bool) {
        hapticOnComplete = enabled
        persist()
    }

    func setSoundOnComplete(_ enabled: Bool) {
        soundOnComplete = enabled
        persist()
    }

    func addSplitExpenses(
        lines: [(category: String, amount: Double)],
        date: Date,
        payee: String,
        note: String
    ) {
        let group = UUID()
        let trimmedPayee = payee.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        for line in lines where line.amount > 0 {
            addExpense(
                ExpenseEntry(
                    amount: line.amount,
                    date: date,
                    category: line.category,
                    note: trimmedNote,
                    payee: trimmedPayee,
                    splitGroupID: group
                ),
                createFollowUp: false
            )
        }
    }

    func postDueRecurrences(now: Date = Date()) {
        let monthKey = Self.monthKey(now)
        let calendar = Calendar.current
        var changed = false
        for index in recurrences.indices {
            guard recurrences[index].lastPostedKey != monthKey else { continue }
            guard recurrences[index].amount > 0 else { continue }
            let day = min(
                recurrences[index].dayOfMonth,
                calendar.range(of: .day, in: .month, for: now)?.count ?? 28
            )
            var comps = calendar.dateComponents([.year, .month], from: now)
            comps.day = day
            guard let due = calendar.date(from: comps) else { continue }
            let dueDay = calendar.startOfDay(for: due)
            guard calendar.startOfDay(for: now) >= dueDay else { continue }
            recurrences[index].lastPostedKey = monthKey
            addExpense(
                ExpenseEntry(
                    amount: recurrences[index].amount,
                    date: due,
                    category: recurrences[index].category,
                    note: "Standing · \(recurrences[index].title)",
                    payee: recurrences[index].payee
                ),
                createFollowUp: false
            )
            changed = true
        }
        if changed {
            persist()
        }
    }

    func setDefaultCategory(_ name: String) {
        if categories.contains(name) {
            defaultCategory = name
            persist()
        }
    }

    func spent(in category: String, monthOf date: Date) -> Double {
        expenses
            .filter { $0.category == category && Self.isSameMonth($0.date, date) }
            .reduce(0) { $0 + $1.amount }
    }

    func leftover(in category: String, monthOf date: Date) -> Double? {
        guard let cap = monthlyBudget[category], cap > 0 else { return nil }
        return cap - spent(in: category, monthOf: date)
    }

    func monthTotal(from date: Date = Date()) -> Double {
        expenses(inMonthOf: date).reduce(0) { $0 + $1.amount }
    }

    func dailySpend(inMonthOf date: Date) -> [(day: Date, total: Double)] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let today = calendar.startOfDay(for: Date())
        var buckets: [Date: Double] = [:]
        var cursor = interval.start
        while cursor < interval.end && cursor <= today {
            buckets[cursor] = 0
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        for item in expenses(inMonthOf: date) {
            let day = calendar.startOfDay(for: item.date)
            if buckets[day] != nil {
                buckets[day, default: 0] += item.amount
            }
        }
        return buckets.keys.sorted().map { ($0, buckets[$0] ?? 0) }
    }

    func trailingMonthTotals(count: Int, from date: Date = Date()) -> [(month: Date, total: Double)] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let start = calendar.date(from: comps) else { return [] }
        return (0..<count).reversed().compactMap { offset -> (Date, Double)? in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: start) else { return nil }
            return (month, monthTotal(from: month))
        }
    }

    func sessionDays(last days: Int, from date: Date = Date()) -> [(day: Date, count: Int)] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        return (0..<days).reversed().compactMap { offset -> (Date, Int)? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start) else { return nil }
            let count = sessionHistory.filter { calendar.isDate($0, inSameDayAs: day) }.count
            return (day, count)
        }
    }

    func focusStreak(from date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let stamped = Set(sessionHistory.map { calendar.startOfDay(for: $0) })
        var cursor = calendar.startOfDay(for: date)
        if !stamped.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while stamped.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    func repeatLatestExpense() {
        guard let last = expenses.first else { return }
        addExpense(
            ExpenseEntry(
                amount: last.amount,
                date: Date(),
                category: last.category,
                note: last.note,
                payee: last.payee
            ),
            createFollowUp: false
        )
    }

    func envelope(from date: Date = Date()) -> EnvelopeSnapshot {
        let calendar = Calendar.current
        let remainingCaps = categories.reduce(0.0) { partial, name in
            guard let leftover = leftover(in: name, monthOf: date) else { return partial }
            return partial + leftover
        }
        let hasCaps = monthlyBudget.values.contains { $0 > 0 }
        let today = calendar.startOfDay(for: date)
        var daysLeft = 1
        if let interval = calendar.dateInterval(of: .month, for: date) {
            daysLeft = max(1, calendar.dateComponents([.day], from: today, to: interval.end).day ?? 1)
        }
        let daily = hasCaps ? max(0, remainingCaps) / Double(daysLeft) : 0
        let spentToday = expenses
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.amount }
        let thisWeek = weekTotal(offset: 0, from: date)
        let lastWeek = weekTotal(offset: -1, from: date)
        var daysLeftInWeek = 1
        if let week = calendar.dateInterval(of: .weekOfYear, for: date) {
            daysLeftInWeek = max(1, calendar.dateComponents([.day], from: today, to: week.end).day ?? 1)
        }
        let weekEnvelope = daily * Double(daysLeftInWeek)
        return EnvelopeSnapshot(
            remainingCaps: remainingCaps,
            daysLeftInMonth: daysLeft,
            dailyLimit: daily,
            spentToday: spentToday,
            leftToday: daily - spentToday,
            thisWeek: thisWeek,
            lastWeek: lastWeek,
            weekEnvelope: weekEnvelope,
            leftThisWeek: weekEnvelope - thisWeek,
            hasCaps: hasCaps
        )
    }

    func weekTotal(offset: Int, from date: Date = Date()) -> Double {
        let calendar = Calendar.current
        guard let shifted = calendar.date(byAdding: .weekOfYear, value: offset, to: date),
              let interval = calendar.dateInterval(of: .weekOfYear, for: shifted) else {
            return 0
        }
        return expenses
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .reduce(0) { $0 + $1.amount }
    }

    func weekComparisonRows(from date: Date = Date()) -> [(label: String, total: Double)] {
        [
            ("Last week", weekTotal(offset: -1, from: date)),
            ("This week", weekTotal(offset: 0, from: date))
        ]
    }

    func payeeTotals(inMonthOf date: Date) -> [(payee: String, total: Double)] {
        var buckets: [String: Double] = [:]
        for item in expenses(inMonthOf: date) {
            let name = item.payee.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = name.isEmpty ? "Unlabeled" : name
            buckets[key, default: 0] += item.amount
        }
        return buckets
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }

    func expenses(inMonthOf date: Date) -> [ExpenseEntry] {
        expenses.filter { Self.isSameMonth($0.date, date) }
    }

    func priorMonthGroups(from date: Date = Date()) -> [(month: Date, items: [ExpenseEntry])] {
        let calendar = Calendar.current
        var buckets: [Date: [ExpenseEntry]] = [:]
        for item in expenses {
            guard !Self.isSameMonth(item.date, date) else { continue }
            let comps = calendar.dateComponents([.year, .month], from: item.date)
            if let key = calendar.date(from: comps) {
                buckets[key, default: []].append(item)
            }
        }
        return buckets.keys.sorted(by: >).map { key in
            let items = (buckets[key] ?? []).sorted { $0.date > $1.date }
            return (key, items)
        }
    }

    func sessionsThisMonth(from date: Date = Date()) -> Int {
        sessionHistory.filter { Self.isSameMonth($0, date) }.count
    }

    func resetAllData() {
        ticker?.invalidate()
        ticker = nil
        wellDoneWork?.cancel()
        wellDoneWork = nil

        for key in LedgerStore.allStoreKeys {
            defaults.removeObject(forKey: key)
        }

        duties = []
        expenses = []
        categories = LedgerStore.defaultCategories
        monthlyBudget = [:]
        focusDurationMin = 25
        breakDurationMin = 5
        sessionHistory = []
        completedSessionsToday = 0
        sessionsDayKey = Self.dayKey(Date())
        lastTaskUpdate = Date()
        defaultCategory = "Groceries"
        timerRunning = false
        timerEndsAt = nil
        isBreak = false
        remainingSnapshot = 25 * 60
        pausedByScene = false
        durationNotice = ""
        showWellDone = false
        recurrences = []
        savingsGoals = []
        dutyTemplates = []
        monthlyBudgetHistory = [:]
        hapticOnComplete = true
        soundOnComplete = true

        NotificationCenter.default.post(name: LedgerStore.dataResetName, object: nil)
        installTicker()
    }

    private func installTicker() {
        ticker?.invalidate()
        ticker = nil
        guard timerRunning else { return }
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        rollDailySessionsIfNeeded()
        if timerRunning, let end = timerEndsAt, Date() >= end {
            finishCycle()
            return
        }
        if timerRunning, Date().timeIntervalSince(lastPersistAt) > 8 {
            persistTimerKeysOnly()
        }
    }

    private func persistTimerKeysOnly() {
        defaults.set(timerRunning, forKey: Keys.timerRunning)
        if let timerEndsAt {
            encode(timerEndsAt, key: Keys.timerEndsAt)
        } else {
            defaults.removeObject(forKey: Keys.timerEndsAt)
        }
        defaults.set(isBreak, forKey: Keys.isBreak)
        defaults.set(remainingSnapshot, forKey: Keys.remainingSnapshot)
        defaults.set(pausedByScene, forKey: Keys.pausedByScene)
        lastPersistAt = Date()
    }

    private func finishCycle() {
        timerRunning = false
        timerEndsAt = nil
        pausedByScene = false

        if isBreak {
            isBreak = false
            remainingSnapshot = Double(focusDurationMin * 60)
            persist()
            return
        }

        sessionHistory.insert(Date(), at: 0)
        completedSessionsToday += 1
        isBreak = true
        remainingSnapshot = Double(breakDurationMin * 60)
        triggerWellDone()
        persist()
        startTimer()
    }

    private func triggerWellDone() {
        showWellDone = true
        FocusCue.play(haptic: hapticOnComplete, sound: soundOnComplete)
        wellDoneWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.showWellDone = false
        }
        wellDoneWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8, execute: work)
    }

    private func sanitizeDurations() {
        var notice: [String] = []
        if !(15...60).contains(focusDurationMin) {
            focusDurationMin = 25
            notice.append("Focus length was reset to 25 minutes.")
            if !timerRunning && !isBreak {
                remainingSnapshot = Double(focusDurationMin * 60)
            }
        }
        if !(5...20).contains(breakDurationMin) {
            breakDurationMin = 5
            notice.append("Break length was reset to 5 minutes.")
            if !timerRunning && isBreak {
                remainingSnapshot = Double(breakDurationMin * 60)
            }
        }
        if remainingSnapshot > currentCycleSeconds() {
            remainingSnapshot = currentCycleSeconds()
        }
        durationNotice = notice.joined(separator: " ")
        if !notice.isEmpty {
            persist()
        }
    }

    private func reconcileTimerOnLaunch() {
        if timerRunning, let end = timerEndsAt {
            let left = end.timeIntervalSinceNow
            remainingSnapshot = max(0, left)
            timerRunning = false
            timerEndsAt = nil
            pausedByScene = remainingSnapshot > 0
        } else if remainingSnapshot <= 0 {
            remainingSnapshot = currentCycleSeconds()
        }
    }

    private func rollDailySessionsIfNeeded() {
        let today = Self.dayKey(Date())
        if sessionsDayKey != today {
            sessionsDayKey = today
            completedSessionsToday = sessionHistory.filter { Calendar.current.isDateInToday($0) }.count
            persist()
        }
    }

    private func loadAll() {
        duties = decodeArray(BudgetDuty.self, key: Keys.duties)
        expenses = decodeArray(ExpenseEntry.self, key: Keys.expenses)

        let loadedCategories = decodeValue([String].self, key: Keys.categories, fallback: LedgerStore.defaultCategories)
        categories = loadedCategories.isEmpty ? LedgerStore.defaultCategories : loadedCategories

        monthlyBudget = decodeValue([String: Double].self, key: Keys.monthlyBudget, fallback: [:])
            .filter { $0.value.isFinite }

        focusDurationMin = decodeValue(Int.self, key: Keys.focusDurationMin, fallback: 25)
        breakDurationMin = decodeValue(Int.self, key: Keys.breakDurationMin, fallback: 5)
        sessionHistory = decodeArray(Date.self, key: Keys.sessionHistory)
        completedSessionsToday = decodeValue(Int.self, key: Keys.completedSessionsToday, fallback: 0)
        sessionsDayKey = decodeValue(String.self, key: Keys.sessionsDayKey, fallback: Self.dayKey(Date()))
        lastTaskUpdate = decodeValue(Date.self, key: Keys.lastTaskUpdate, fallback: Date())

        let loadedDefault = decodeValue(String.self, key: Keys.defaultCategory, fallback: "Groceries")
        defaultCategory = categories.contains(loadedDefault) ? loadedDefault : (categories.first ?? "Groceries")

        timerRunning = decodeValue(Bool.self, key: Keys.timerRunning, fallback: false)
        timerEndsAt = decodeOptional(Date.self, key: Keys.timerEndsAt)
        isBreak = decodeValue(Bool.self, key: Keys.isBreak, fallback: false)
        remainingSnapshot = decodeValue(TimeInterval.self, key: Keys.remainingSnapshot, fallback: 25 * 60)
        pausedByScene = decodeValue(Bool.self, key: Keys.pausedByScene, fallback: false)
        recurrences = decodeArray(RecurringCharge.self, key: Keys.recurrences)
        savingsGoals = decodeArray(SavingsGoal.self, key: Keys.savingsGoals)
        dutyTemplates = decodeArray(DutyTemplate.self, key: Keys.dutyTemplates)
        monthlyBudgetHistory = decodeValue([String: [String: Double]].self, key: Keys.monthlyBudgetHistory, fallback: [:])
        hapticOnComplete = defaults.object(forKey: Keys.hapticOnComplete) == nil
            ? true
            : defaults.bool(forKey: Keys.hapticOnComplete)
        soundOnComplete = defaults.object(forKey: Keys.soundOnComplete) == nil
            ? true
            : defaults.bool(forKey: Keys.soundOnComplete)

        if remainingSnapshot < 0 || !remainingSnapshot.isFinite || remainingSnapshot > currentCycleSeconds() {
            remainingSnapshot = currentCycleSeconds()
        }
    }

    private func persist() {
        encode(duties, key: Keys.duties)
        encode(expenses, key: Keys.expenses)
        encode(categories, key: Keys.categories)
        encode(monthlyBudget, key: Keys.monthlyBudget)
        defaults.set(focusDurationMin, forKey: Keys.focusDurationMin)
        defaults.set(breakDurationMin, forKey: Keys.breakDurationMin)
        encode(sessionHistory, key: Keys.sessionHistory)
        defaults.set(completedSessionsToday, forKey: Keys.completedSessionsToday)
        defaults.set(sessionsDayKey, forKey: Keys.sessionsDayKey)
        encode(lastTaskUpdate, key: Keys.lastTaskUpdate)
        defaults.set(defaultCategory, forKey: Keys.defaultCategory)
        defaults.set(timerRunning, forKey: Keys.timerRunning)
        if let timerEndsAt = timerEndsAt {
            encode(timerEndsAt, key: Keys.timerEndsAt)
        } else {
            defaults.removeObject(forKey: Keys.timerEndsAt)
        }
        defaults.set(isBreak, forKey: Keys.isBreak)
        defaults.set(remainingSnapshot, forKey: Keys.remainingSnapshot)
        defaults.set(pausedByScene, forKey: Keys.pausedByScene)
        encode(recurrences, key: Keys.recurrences)
        encode(savingsGoals, key: Keys.savingsGoals)
        encode(dutyTemplates, key: Keys.dutyTemplates)
        encode(monthlyBudgetHistory, key: Keys.monthlyBudgetHistory)
        defaults.set(hapticOnComplete, forKey: Keys.hapticOnComplete)
        defaults.set(soundOnComplete, forKey: Keys.soundOnComplete)
        lastPersistAt = Date()
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            defaults.removeObject(forKey: key)
        }
    }

    private func decodeValue<T: Decodable>(_ type: T.Type, key: String, fallback: T) -> T {
        if let stored = defaults.object(forKey: key) as? T {
            return stored
        }
        guard let data = defaults.data(forKey: key) else { return fallback }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            defaults.removeObject(forKey: key)
            return fallback
        }
    }

    private func decodeOptional<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            defaults.removeObject(forKey: key)
            return nil
        }
    }

    private func decodeArray<T: Decodable>(_ type: T.Type, key: String) -> [T] {
        guard let data = defaults.data(forKey: key) else { return [] }
        if let items = try? decoder.decode([T].self, from: data) {
            return items
        }
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            defaults.removeObject(forKey: key)
            return []
        }
        let recovered: [T] = raw.compactMap { item in
            guard JSONSerialization.isValidJSONObject(item),
                  let itemData = try? JSONSerialization.data(withJSONObject: item) else {
                if item is String || item is NSNumber {
                    return nil
                }
                return nil
            }
            return try? decoder.decode(T.self, from: itemData)
        }
        if recovered.isEmpty {
            defaults.removeObject(forKey: key)
        }
        return recovered
    }

    private func snapshotCapsForCurrentMonth() {
        monthlyBudgetHistory[Self.monthKey(Date())] = monthlyBudget
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func monthKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        let calendar = Calendar.current
        let left = calendar.dateComponents([.year, .month], from: lhs)
        let right = calendar.dateComponents([.year, .month], from: rhs)
        return left.year == right.year && left.month == right.month
    }

    static func endOfMonth(from date: Date) -> Date {
        let calendar = Calendar.current
        if let interval = calendar.dateInterval(of: .month, for: date) {
            return interval.end.addingTimeInterval(-1)
        }
        return date
    }
}
