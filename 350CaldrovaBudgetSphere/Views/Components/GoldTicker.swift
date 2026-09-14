import SwiftUI

enum LedgerPane: String, CaseIterable, Identifiable {
    case duties = "Duties"
    case clock = "Clock"
    case spend = "Spend"
    case stats = "Stats"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .duties:
            return "checklist"
        case .clock:
            return "clock.arrow.circlepath"
        case .spend:
            return "chart.pie.fill"
        case .stats:
            return "chart.xyaxis.line"
        }
    }
}

struct GoldTicker: View {
    @Binding var selection: LedgerPane

    var body: some View {
        HStack(spacing: 3) {
            ForEach(LedgerPane.allCases) { pane in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = pane
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: pane.symbol)
                            .font(.system(size: 12, weight: .semibold))
                        Text(pane.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .serif))
                            .tracking(0.4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .foregroundColor(selection == pane ? Palette.background : Palette.primary)
                    .background(knob(for: pane))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Palette.surface, Palette.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Palette.primary, lineWidth: 1.2)
                )
                .shadow(color: Palette.primary.opacity(0.32), radius: 7, x: 0, y: 3)
        )
    }

    @ViewBuilder
    private func knob(for pane: LedgerPane) -> some View {
        if selection == pane {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Palette.primary, Palette.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Palette.accent.opacity(0.45), radius: 4, x: 0, y: 1)
        } else {
            Capsule(style: .continuous)
                .fill(Palette.background.opacity(0.35))
        }
    }
}
