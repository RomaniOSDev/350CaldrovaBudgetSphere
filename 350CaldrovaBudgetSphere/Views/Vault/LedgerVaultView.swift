import SwiftUI
import UIKit

struct LedgerVaultView: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    vaultRow(title: "Rate Us", symbol: "star.fill") {
                        AppLinks.rateApp()
                    }
                    vaultRow(title: "Privacy", symbol: "lock.rectangle") {
                        open(AppLinks.privacy)
                    }
                    vaultRow(title: "Terms", symbol: "doc.text") {
                        open(AppLinks.terms)
                    }

                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("FOCUS CUES")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .tracking(1.1)
                                .foregroundColor(Palette.accent)
                            Toggle("Haptic on complete", isOn: hapticBinding)
                                .tint(Palette.primary)
                                .foregroundColor(Palette.primary)
                            Toggle("Sound on complete", isOn: soundBinding)
                                .tint(Palette.primary)
                                .foregroundColor(Palette.primary)
                            Text("Plays when a focus cycle closes.")
                                .font(.caption)
                                .foregroundColor(Palette.primary.opacity(0.75))
                        }
                    }

                    LedgerPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DEFAULT CATEGORY")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .tracking(1.1)
                                .foregroundColor(Palette.accent)
                            Picker("Default Category", selection: defaultCategoryBinding) {
                                ForEach(store.categories, id: \.self) { name in
                                    Text(name).tag(name)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Palette.primary)
                            Text("New duties and expenses start here.")
                                .font(.caption)
                                .foregroundColor(Palette.primary.opacity(0.75))
                        }
                    }

                    Button {
                        confirmReset = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(Palette.background)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Palette.accent))
                            Text("Reset All Data")
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Palette.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Palette.surface, Palette.background.opacity(0.92)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Palette.accent, lineWidth: 1.15)
                            )
                            .shadow(color: Palette.accent.opacity(0.22), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(16)
            }
            .studioBackdrop()
            .navigationTitle("Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Palette.primary)
                }
            }
            .alert("Reset All Data", isPresented: $confirmReset) {
                Button("Reset All Data", role: .destructive) {
                    store.resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears duties, expenses, budgets, and focus history.")
            }
        }
        .tint(Palette.primary)
    }

    private var defaultCategoryBinding: Binding<String> {
        Binding(
            get: { store.defaultCategory },
            set: { store.setDefaultCategory($0) }
        )
    }

    private var hapticBinding: Binding<Bool> {
        Binding(
            get: { store.hapticOnComplete },
            set: { store.setHapticOnComplete($0) }
        )
    }

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { store.soundOnComplete },
            set: { store.setSoundOnComplete($0) }
        )
    }

    private func vaultRow(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .foregroundColor(Palette.background)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [Palette.primary, Palette.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    )
                Text(title)
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(Palette.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Palette.accent)
            }
        }
        .buttonStyle(.plain)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Palette.surface, Palette.background.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Palette.primary, lineWidth: 1.15)
                )
                .shadow(color: Palette.primary.opacity(0.22), radius: 8, x: 0, y: 4)
        )
    }

    private func open(_ link: AppLinks) {
        guard let url = URL(string: link.rawValue) else { return }
        UIApplication.shared.open(url)
    }
}
