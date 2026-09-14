import Foundation

enum DutyPriority: String, Codable, CaseIterable, Identifiable {
    case high
    case monthReview
    case normal

    var id: String { rawValue }

    var ledgerTitle: String {
        switch self {
        case .high:
            return "High"
        case .monthReview:
            return "Month Review"
        case .normal:
            return "Ledger"
        }
    }

    var sortIndex: Int {
        switch self {
        case .high:
            return 0
        case .monthReview:
            return 1
        case .normal:
            return 2
        }
    }
}

struct BudgetDuty: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var category: String
    var priority: DutyPriority
    var dueDate: Date
    var completedAt: Date?
    var linkedExpenseID: UUID?

    var isSettled: Bool { completedAt != nil }

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        priority: DutyPriority = .normal,
        dueDate: Date,
        completedAt: Date? = nil,
        linkedExpenseID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.priority = priority
        self.dueDate = dueDate
        self.completedAt = completedAt
        self.linkedExpenseID = linkedExpenseID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        category = (try? container.decode(String.self, forKey: .category)) ?? ""
        if let raw = try? container.decode(String.self, forKey: .priority),
           let parsed = DutyPriority(rawValue: raw) {
            priority = parsed
        } else {
            priority = .normal
        }
        dueDate = (try? container.decode(Date.self, forKey: .dueDate)) ?? Date()
        completedAt = try? container.decode(Date.self, forKey: .completedAt)
        linkedExpenseID = try? container.decode(UUID.self, forKey: .linkedExpenseID)
    }
}

struct ExpenseEntry: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var amount: Double
    var date: Date
    var category: String
    var note: String
    var payee: String
    var splitGroupID: UUID?

    init(
        id: UUID = UUID(),
        amount: Double,
        date: Date = Date(),
        category: String,
        note: String = "",
        payee: String = "",
        splitGroupID: UUID? = nil
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.category = category
        self.note = note
        self.payee = payee
        self.splitGroupID = splitGroupID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let rawAmount = try container.decodeIfPresent(Double.self, forKey: .amount) ?? 0
        amount = rawAmount.isFinite ? rawAmount : 0
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        payee = try container.decodeIfPresent(String.self, forKey: .payee) ?? ""
        splitGroupID = try container.decodeIfPresent(UUID.self, forKey: .splitGroupID)
    }
}

struct RecurringCharge: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var amount: Double
    var category: String
    var payee: String
    var dayOfMonth: Int
    var lastPostedKey: String

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: String,
        payee: String = "",
        dayOfMonth: Int,
        lastPostedKey: String = ""
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.payee = payee
        self.dayOfMonth = min(28, max(1, dayOfMonth))
        self.lastPostedKey = lastPostedKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        let raw = (try? container.decode(Double.self, forKey: .amount)) ?? 0
        amount = raw.isFinite ? raw : 0
        category = (try? container.decode(String.self, forKey: .category)) ?? ""
        payee = (try? container.decode(String.self, forKey: .payee)) ?? ""
        let day = (try? container.decode(Int.self, forKey: .dayOfMonth)) ?? 1
        dayOfMonth = min(28, max(1, day))
        lastPostedKey = (try? container.decode(String.self, forKey: .lastPostedKey)) ?? ""
    }
}

struct SavingsGoal: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var target: Double
    var saved: Double

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, saved / target))
    }

    init(
        id: UUID = UUID(),
        name: String,
        target: Double,
        saved: Double = 0
    ) {
        self.id = id
        self.name = name
        self.target = target.isFinite ? max(0, target) : 0
        self.saved = saved.isFinite ? max(0, saved) : 0
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        let rawTarget = (try? container.decode(Double.self, forKey: .target)) ?? 0
        target = rawTarget.isFinite ? max(0, rawTarget) : 0
        let rawSaved = (try? container.decode(Double.self, forKey: .saved)) ?? 0
        saved = rawSaved.isFinite ? max(0, rawSaved) : 0
    }
}

struct DutyTemplate: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var category: String
    var priority: DutyPriority

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        priority: DutyPriority = .normal
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.priority = priority
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        category = (try? container.decode(String.self, forKey: .category)) ?? ""
        if let raw = try? container.decode(String.self, forKey: .priority),
           let parsed = DutyPriority(rawValue: raw) {
            priority = parsed
        } else {
            priority = .normal
        }
    }
}

struct EnvelopeSnapshot {
    var remainingCaps: Double
    var daysLeftInMonth: Int
    var dailyLimit: Double
    var spentToday: Double
    var leftToday: Double
    var thisWeek: Double
    var lastWeek: Double
    var weekEnvelope: Double
    var leftThisWeek: Double
    var hasCaps: Bool
}

struct SessionStamp: Identifiable, Codable, Hashable {
    var date: Date

    var id: Date { date }

    init(_ date: Date = Date()) {
        self.date = date
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let value = try? container.decode(Date.self) {
            date = value
            return
        }
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        date = try keyed.decodeIfPresent(Date.self, forKey: .date) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(date)
    }

    private enum CodingKeys: String, CodingKey {
        case date
    }
}
