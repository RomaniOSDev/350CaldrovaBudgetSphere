import SwiftUI

struct SavingsEditorSheet: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss

    let existing: SavingsGoal?

    @State private var name: String = ""
    @State private var targetText: String = ""
    @State private var savedText: String = ""
    @State private var adjustText: String = ""
    @State private var message: String = ""

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            caption("Goal")
                            TextField("Emergency fund", text: $name)
                                .textInputAutocapitalization(.sentences)
                                .foregroundColor(Palette.primary)
                        }
                    }
                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            caption("Target")
                            TextField("0.00", text: $targetText)
                                .keyboardType(.decimalPad)
                                .font(.system(.title3, design: .monospaced))
                                .foregroundColor(Palette.primary)
                        }
                    }
                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            caption("Already saved")
                            TextField("0.00", text: $savedText)
                                .keyboardType(.decimalPad)
                                .font(.system(.title3, design: .monospaced))
                                .foregroundColor(Palette.primary)
                        }
                    }
                    if isEditing {
                        LedgerPlate {
                            VStack(alignment: .leading, spacing: 8) {
                                caption("Move funds")
                                TextField("Amount", text: $adjustText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(Palette.primary)
                                HStack(spacing: 8) {
                                    Button("Deposit") { applyAdjust(sign: 1) }
                                        .buttonStyle(.plain)
                                        .foregroundColor(Palette.background)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Palette.primary))
                                    Button("Withdraw") { applyAdjust(sign: -1) }
                                        .buttonStyle(.plain)
                                        .foregroundColor(Palette.background)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Palette.accent))
                                }
                            }
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
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
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

    private func hydrate() {
        if let existing {
            name = existing.name
            targetText = String(format: "%.2f", existing.target)
            savedText = existing.saved > 0 ? String(format: "%.2f", existing.saved) : ""
        }
    }

    private func parseOptional(_ raw: String) -> Double {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        return MoneyText.parse(trimmed) ?? 0
    }

    private func applyAdjust(sign: Double) {
        guard let existing, let amount = MoneyText.parse(adjustText) else {
            message = "Enter an amount to move."
            return
        }
        store.adjustSavings(existing, delta: amount * sign)
        dismiss()
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            message = "Goal name is required."
            return
        }
        guard let target = MoneyText.parse(targetText) else {
            message = "Target must be greater than zero."
            return
        }
        let saved = parseOptional(savedText)
        if var current = existing {
            current.name = trimmed
            current.target = target
            current.saved = saved
            store.updateSavingsGoal(current)
        } else {
            store.addSavingsGoal(SavingsGoal(name: trimmed, target: target, saved: saved))
        }
        dismiss()
    }
}
