import SwiftUI

struct ContentView: View {
    @StateObject private var store = LedgerStore()
    @State private var pane: LedgerPane = .duties
    @State private var showVault = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                GoldTicker(selection: $pane)
                Button {
                    showVault = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Palette.background)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle().fill(
                                LinearGradient(
                                    colors: [Palette.primary, Palette.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .overlay(
                            Circle().stroke(Palette.accent.opacity(0.7), lineWidth: 1)
                        )
                        .shadow(color: Palette.primary.opacity(0.38), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Vault")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Group {
                switch pane {
                case .duties:
                    DutyBoardView()
                case .clock:
                    FocusClockView()
                case .spend:
                    SpendInsightsView()
                case .stats:
                    LedgerStatsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .studioBackdrop()
        .foldKeyboardOnTap()
        .environmentObject(store)
        .sheet(isPresented: $showVault) {
            LedgerVaultView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { newPhase in
            store.handleScenePhase(newPhase)
        }
        .onReceive(NotificationCenter.default.publisher(for: LedgerStore.dataResetName)) { _ in
            pane = .duties
            showVault = false
        }
    }
}
