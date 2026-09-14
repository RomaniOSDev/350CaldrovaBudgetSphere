import SwiftUI

struct DutyEditorSheet: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss

    let existing: BudgetDuty?

    @State private var title: String = ""
    @State private var category: String = ""
    @State private var priority: DutyPriority = .normal
    @State private var dueDate: Date = Date()
    @State private var message: String = ""

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            fieldCaption("Title")
                            TextField("What needs attention?", text: $title)
                                .textInputAutocapitalization(.sentences)
                                .foregroundColor(Palette.primary)
                        }
                    }

                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            fieldCaption("Category")
                            Picker("Category", selection: $category) {
                                ForEach(store.categories, id: \.self) { name in
                                    Text(name).tag(name)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Palette.primary)
                        }
                    }

                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            fieldCaption("Priority")
                            Picker("Priority", selection: $priority) {
                                ForEach(DutyPriority.allCases) { item in
                                    Text(item.ledgerTitle).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    LedgerPlate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                            .tint(Palette.primary)
                            .foregroundColor(Palette.primary)
                    }

                    Button {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            message = "Title is required."
                            return
                        }
                        store.saveDutyTemplate(title: trimmed, category: category, priority: priority)
                        message = "Saved as a template."
                    } label: {
                        Text("Save as template")
                            .font(.system(.caption, design: .serif).weight(.bold))
                            .foregroundColor(Palette.primary)
                    }
                    .buttonStyle(.plain)

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
            .navigationTitle(isEditing ? "Edit Duty" : "New Duty")
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

    private func fieldCaption(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .serif))
            .tracking(1.1)
            .foregroundColor(Palette.accent)
    }

    private func hydrate() {
        if let existing = existing {
            title = existing.title
            category = existing.category
            priority = existing.priority
            dueDate = existing.dueDate
        } else {
            category = store.categories.contains(store.defaultCategory)
                ? store.defaultCategory
                : (store.categories.first ?? "")
            dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            message = "Title is required."
            return
        }
        if category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            message = "Category is required."
            return
        }

        if var current = existing {
            current.title = trimmed
            current.category = category
            current.priority = priority
            current.dueDate = dueDate
            store.updateDuty(current)
        } else {
            store.addDuty(
                BudgetDuty(
                    title: trimmed,
                    category: category,
                    priority: priority,
                    dueDate: dueDate
                )
            )
        }
        dismiss()
    }
}
