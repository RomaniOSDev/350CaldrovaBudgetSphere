import SwiftUI

struct RecurringEditorSheet: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss

    let existing: RecurringCharge?

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var category: String = ""
    @State private var payee: String = ""
    @State private var dayOfMonth: Int = 1
    @State private var message: String = ""

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    plate("Title") {
                        TextField("Rent, Netflix…", text: $title)
                            .textInputAutocapitalization(.words)
                            .foregroundColor(Palette.primary)
                    }
                    plate("Amount") {
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(.title3, design: .monospaced))
                            .foregroundColor(Palette.primary)
                    }
                    plate("Category") {
                        Picker("Category", selection: $category) {
                            ForEach(store.categories, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Palette.primary)
                    }
                    plate("Payee") {
                        TextField("Landlord, merchant…", text: $payee)
                            .textInputAutocapitalization(.words)
                            .foregroundColor(Palette.primary)
                    }
                    plate("Day of month") {
                        Stepper(value: $dayOfMonth, in: 1...28) {
                            Text("Posts on day \(dayOfMonth)")
                                .font(.system(.subheadline, design: .serif))
                                .foregroundColor(Palette.primary)
                        }
                        .tint(Palette.primary)
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
            .navigationTitle(isEditing ? "Edit Standing" : "New Standing")
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

    private func plate<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        let inner = content()
        return LedgerPlate {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.1)
                    .foregroundColor(Palette.accent)
                inner
            }
        }
    }

    private func hydrate() {
        if let existing {
            title = existing.title
            amountText = String(format: "%.2f", existing.amount)
            category = existing.category
            payee = existing.payee
            dayOfMonth = existing.dayOfMonth
        } else {
            category = store.categories.contains(store.defaultCategory)
                ? store.defaultCategory
                : (store.categories.first ?? "")
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            message = "Title is required."
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
            current.title = trimmed
            current.amount = amount
            current.category = category
            current.payee = payee.trimmingCharacters(in: .whitespacesAndNewlines)
            current.dayOfMonth = dayOfMonth
            store.updateRecurrence(current)
        } else {
            store.addRecurrence(
                RecurringCharge(
                    title: trimmed,
                    amount: amount,
                    category: category,
                    payee: payee.trimmingCharacters(in: .whitespacesAndNewlines),
                    dayOfMonth: dayOfMonth
                )
            )
        }
        dismiss()
    }
}
