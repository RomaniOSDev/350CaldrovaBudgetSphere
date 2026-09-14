import Charts
import SwiftUI

struct LedgerStatsView: View {
    @EnvironmentObject private var store: LedgerStore

    private var monthAnchor: Date { Date() }

    private var categoryRows: [CategorySpend] {
        store.categories.map { name in
            CategorySpend(name: name, spent: store.spent(in: name, monthOf: monthAnchor))
        }
    }

    private var dailyRows: [DaySpend] {
        store.dailySpend(inMonthOf: monthAnchor).map { DaySpend(day: $0.day, total: $0.total) }
    }

    private var monthRows: [MonthSpend] {
        store.trailingMonthTotals(count: 6, from: monthAnchor).map {
            MonthSpend(month: $0.month, total: $0.total)
        }
    }

    private var sessionRows: [DaySessions] {
        store.sessionDays(last: 7, from: monthAnchor).map {
            DaySessions(day: $0.day, count: $0.count)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GoldBanner(imageName: "BannerChart")
                summaryPlate
                weekChart
                categoryChart
                payeeChart
                dailyChart
                historyChart
                focusChart
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private var summaryPlate: some View {
        let thisMonth = store.monthTotal(from: monthAnchor)
        let lastAnchor = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor
        let lastMonth = store.monthTotal(from: lastAnchor)
        let openDuties = store.duties.filter { !$0.isSettled }.count
        let overdue = store.duties.filter { isOverdue($0) }.count
        let streak = store.focusStreak(from: monthAnchor)
        let delta = lastMonth > 0 ? ((thisMonth - lastMonth) / lastMonth) * 100 : 0

        return LedgerPlate {
            VStack(alignment: .leading, spacing: 10) {
                Text("THIS MONTH")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    MoneyText(amount: thisMonth, size: .system(size: 28, weight: .bold, design: .monospaced))
                    if lastMonth > 0 {
                        Text(delta >= 0 ? String(format: "+%.0f%% vs last", delta) : String(format: "%.0f%% vs last", delta))
                            .font(.system(size: 12, weight: .semibold, design: .serif))
                            .foregroundColor(delta > 0 ? Palette.accent : Palette.primary)
                    }
                }
                HStack(spacing: 10) {
                    statChip("\(openDuties)", caption: "open duties")
                    statChip("\(overdue)", caption: "overdue")
                    statChip("\(streak)", caption: "focus streak")
                }
            }
        }
    }

    private var weekChart: some View {
        let rows = store.weekComparisonRows(from: monthAnchor).map { WeekSpend(label: $0.label, total: $0.total) }
        let hasSpend = rows.contains { $0.total > 0 }
        return LedgerPlate {
            VStack(alignment: .leading, spacing: 10) {
                Text("THIS WEEK VS LAST")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                if !hasSpend {
                    emptyNote("Week-to-week bars appear after postings land.")
                } else {
                    Chart(rows) { row in
                        BarMark(
                            x: .value("Week", row.label),
                            y: .value("Spent", row.total)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Palette.primary, Palette.accent],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine().foregroundStyle(Palette.primary.opacity(0.12))
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(shortMoney(amount))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Palette.primary.opacity(0.8))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let label = value.as(String.self) {
                                    Text(label)
                                        .font(.system(size: 10, design: .serif))
                                        .foregroundColor(Palette.primary)
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                    HStack {
                        Text("Last \(MoneyText.format(rows.first?.total ?? 0))")
                        Spacer()
                        Text("This \(MoneyText.format(rows.last?.total ?? 0))")
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Palette.primary)
                }
            }
        }
    }

    private var payeeChart: some View {
        let rows = store.payeeTotals(inMonthOf: monthAnchor).prefix(8).map { PayeeSpend(payee: $0.payee, total: $0.total) }
        return LedgerPlate {
            VStack(alignment: .leading, spacing: 10) {
                Text("BY PAYEE")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                if rows.isEmpty {
                    emptyNote("Add a payee on a posting to group spend here.")
                } else {
                    Chart(rows) { row in
                        BarMark(
                            x: .value("Spent", row.total),
                            y: .value("Payee", row.payee)
                        )
                        .foregroundStyle(Palette.primary)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine().foregroundStyle(Palette.primary.opacity(0.12))
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(shortMoney(amount))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Palette.primary.opacity(0.8))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let name = value.as(String.self) {
                                    Text(name)
                                        .font(.system(size: 10, design: .serif))
                                        .foregroundColor(Palette.primary)
                                }
                            }
                        }
                    }
                    .frame(height: CGFloat(max(140, rows.count * 32)))
                }
            }
        }
    }

    private var categoryChart: some View {
        let rows = categoryRows.filter { $0.spent > 0 }
        return LedgerPlate {
            VStack(alignment: .leading, spacing: 10) {
                Text("SPEND BY CATEGORY")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                if rows.isEmpty {
                    emptyNote("Log a posting to see the category bars.")
                } else {
                    Chart(rows) { row in
                        BarMark(
                            x: .value("Spent", row.spent),
                            y: .value("Category", row.name)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Palette.primary, Palette.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom) { value in
                            AxisGridLine().foregroundStyle(Palette.primary.opacity(0.18))
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(shortMoney(amount))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Palette.primary.opacity(0.8))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let name = value.as(String.self) {
                                    Text(name)
                                        .font(.system(size: 10, design: .serif))
                                        .foregroundColor(Palette.primary)
                                }
                            }
                        }
                    }
                    .frame(height: CGFloat(max(160, rows.count * 36)))
                }
            }
        }
    }

    private var dailyChart: some View {
        let rows = dailyRows
        let hasSpend = rows.contains { $0.total > 0 }
        return LedgerPlate {
            VStack(alignment: .leading, spacing: 10) {
                Text("DAILY FLOW")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                if !hasSpend {
                    emptyNote("Daily spend will plot here as the month fills in.")
                } else {
                    Chart(rows) { row in
                        AreaMark(
                            x: .value("Day", row.day),
                            y: .value("Spent", row.total)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Palette.primary.opacity(0.45), Palette.accent.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        LineMark(
                            x: .value("Day", row.day),
                            y: .value("Spent", row.total)
                        )
                        .foregroundStyle(Palette.primary)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 5)) { value in
                            AxisGridLine().foregroundStyle(Palette.primary.opacity(0.12))
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(Self.day.string(from: date))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Palette.primary.opacity(0.8))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine().foregroundStyle(Palette.primary.opacity(0.12))
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(shortMoney(amount))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Palette.primary.opacity(0.8))
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private var historyChart: some View {
        let rows = monthRows
        let hasSpend = rows.contains { $0.total > 0 }
        return LedgerPlate {
            VStack(alignment: .leading, spacing: 10) {
                Text("LAST SIX MONTHS")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                if !hasSpend {
                    emptyNote("Past months appear once postings land.")
                } else {
                    Chart(rows) { row in
                        BarMark(
                            x: .value("Month", row.month, unit: .month),
                            y: .value("Spent", row.total)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Palette.accent, Palette.primary],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(Self.month.string(from: date))
                                        .font(.system(size: 9, design: .serif))
                                        .foregroundColor(Palette.primary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine().foregroundStyle(Palette.primary.opacity(0.12))
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(shortMoney(amount))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Palette.primary.opacity(0.8))
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private var focusChart: some View {
        let rows = sessionRows
        let hasSessions = rows.contains { $0.count > 0 }
        return LedgerPlate {
            VStack(alignment: .leading, spacing: 10) {
                Text("FOCUS LAST 7 DAYS")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                if !hasSessions {
                    emptyNote("Closed focus cycles will stack on this chart.")
                } else {
                    Chart(rows) { row in
                        BarMark(
                            x: .value("Day", row.day, unit: .day),
                            y: .value("Sessions", row.count)
                        )
                        .foregroundStyle(Palette.primary)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(Self.weekday.string(from: date))
                                        .font(.system(size: 9, design: .serif))
                                        .foregroundColor(Palette.primary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine().foregroundStyle(Palette.primary.opacity(0.12))
                            AxisValueLabel {
                                if let count = value.as(Int.self) {
                                    Text("\(count)")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Palette.primary.opacity(0.8))
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                }
            }
        }
    }

    private func statChip(_ value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(Palette.primary)
            Text(caption)
                .font(.system(size: 10, design: .serif))
                .foregroundColor(Palette.primary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Palette.background.opacity(0.55))
        )
    }

    private func emptyNote(_ text: String) -> some View {
        Text(text)
            .font(.system(.callout, design: .serif))
            .foregroundColor(Palette.primary)
            .padding(.vertical, 8)
    }

    private func isOverdue(_ duty: BudgetDuty) -> Bool {
        !duty.isSettled && duty.dueDate < Calendar.current.startOfDay(for: Date())
    }

    private func shortMoney(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "%.1fk", amount / 1000)
        }
        return String(format: "%.0f", amount)
    }

    private static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let month: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
}

private struct CategorySpend: Identifiable {
    var name: String
    var spent: Double
    var id: String { name }
}

private struct DaySpend: Identifiable {
    var day: Date
    var total: Double
    var id: Date { day }
}

private struct MonthSpend: Identifiable {
    var month: Date
    var total: Double
    var id: Date { month }
}

private struct DaySessions: Identifiable {
    var day: Date
    var count: Int
    var id: Date { day }
}

private struct WeekSpend: Identifiable {
    var label: String
    var total: Double
    var id: String { label }
}

private struct PayeeSpend: Identifiable {
    var payee: String
    var total: Double
    var id: String { payee }
}
