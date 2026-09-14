import SwiftUI

private struct SplitDraft: Identifiable {
    let id = UUID()
    var category: String
    var amountText: String
}

struct ExpenseEditorSheet: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss

    let existing: ExpenseEntry?

    @State private var amountText: String = ""
    @State private var category: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var payee: String = ""
    @State private var splitOn = false
    @State private var splits: [SplitDraft] = []
    @State private var message: String = ""

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            caption("Amount")
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.system(.title3, design: .monospaced))
                                .foregroundColor(Palette.primary)
                                .disabled(splitOn && !isEditing)
                            if !(splitOn && !isEditing) {
                                HStack(spacing: 8) {
                                    ForEach([10, 25, 50, 100], id: \.self) { chip in
                                        Button {
                                            amountText = String(format: "%.2f", Double(chip))
                                        } label: {
                                            Text("\(chip)")
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
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

                    if !isEditing {
                        LedgerPlate {
                            Toggle(isOn: $splitOn) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Split across categories")
                                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                                        .foregroundColor(Palette.primary)
                                    Text("One posting, several ledgers.")
                                        .font(.caption)
                                        .foregroundColor(Palette.primary.opacity(0.7))
                                }
                            }
                            .tint(Palette.primary)
                            .onChange(of: splitOn) { enabled in
                                if enabled { seedSplits() }
                            }
                        }
                    }

                    if splitOn && !isEditing {
                        ForEach($splits) { $line in
                            LedgerPlate {
                                HStack {
                                    Picker("Category", selection: $line.category) {
                                        ForEach(store.categories, id: \.self) { name in
                                            Text(name).tag(name)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Palette.primary)
                                    TextField("0.00", text: $line.amountText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(Palette.primary)
                                        .frame(width: 90)
                                }
                            }
                        }
                        Button {
                            let fallback = store.categories.first ?? ""
                            splits.append(SplitDraft(category: fallback, amountText: ""))
                        } label: {
                            Text("Add split line")
                                .font(.system(.caption, design: .serif).weight(.bold))
                                .foregroundColor(Palette.primary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        LedgerPlate {
                            VStack(alignment: .leading, spacing: 8) {
                                caption("Category")
                                Picker("Category", selection: $category) {
                                    ForEach(store.categories, id: \.self) { name in
                                        Text(name).tag(name)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Palette.primary)
                            }
                        }
                    }

                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            caption("Payee")
                            TextField("Merchant or person", text: $payee)
                                .textInputAutocapitalization(.words)
                                .foregroundColor(Palette.primary)
                        }
                    }

                    LedgerPlate {
                        DatePicker("Posted", selection: $date, displayedComponents: .date)
                            .tint(Palette.primary)
                            .foregroundColor(Palette.primary)
                    }

                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            caption("Note")
                            TextField("Optional memo", text: $note)
                                .foregroundColor(Palette.primary)
                        }
                    }

                    if !message.isEmpty {
                        Text(message)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(Palette.accent)
                    }
                }
                .padding(16)
            }
            .studioBackdrop()
            .keyboardDoneButton()
            .navigationTitle(isEditing ? "Edit Expense" : "Log Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Palette.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .foregroundColor(Palette.primary)
                }
            }
        }
        .tint(Palette.primary)
        .onAppear { hydrate() }
    }

    private func caption(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .serif))
            .tracking(1.1)
            .foregroundColor(Palette.accent)
    }

    private func seedSplits() {
        guard splits.isEmpty else { return }
        let first = store.categories.contains(store.defaultCategory)
            ? store.defaultCategory
            : (store.categories.first ?? "")
        let second = store.categories.first { $0 != first } ?? first
        splits = [
            SplitDraft(category: first, amountText: amountText),
            SplitDraft(category: second, amountText: "")
        ]
    }

    private func hydrate() {
        if let existing {
            amountText = String(format: "%.2f", existing.amount)
            category = existing.category
            date = existing.date
            note = existing.note
            payee = existing.payee
        } else {
            category = store.categories.contains(store.defaultCategory)
                ? store.defaultCategory
                : (store.categories.first ?? "")
            date = Date()
        }
    }

    private func save() {
        let trimmedPayee = payee.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if splitOn, !isEditing {
            let lines: [(String, Double)] = splits.compactMap { line in
                guard let amount = MoneyText.parse(line.amountText) else { return nil }
                let name = line.category.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return nil }
                return (name, amount)
            }
            guard lines.count >= 2 else {
                message = "Add at least two split amounts."
                return
            }
            store.addSplitExpenses(lines: lines, date: date, payee: trimmedPayee, note: trimmedNote)
            dismiss()
            return
        }

        guard let amount = MoneyText.parse(amountText) else {
            message = "Amount must be greater than zero."
            return
        }
        if category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            message = "Category is required."
            return
        }

        if var current = existing {
            current.amount = amount
            current.category = category
            current.date = date
            current.note = trimmedNote
            current.payee = trimmedPayee
            store.updateExpense(current)
        } else {
            store.addExpense(
                ExpenseEntry(
                    amount: amount,
                    date: date,
                    category: category,
                    note: trimmedNote,
                    payee: trimmedPayee
                ),
                createFollowUp: true
            )
        }
        dismiss()
    }
}
