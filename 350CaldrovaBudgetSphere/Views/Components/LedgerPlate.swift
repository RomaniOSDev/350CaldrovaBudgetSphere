import SwiftUI

struct LedgerPlate<Content: View>: View {
    var inset: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(inset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Palette.surface, Palette.background.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(ledgerRules)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Palette.primary, lineWidth: 1.15)
                    )
                    .shadow(color: Palette.primary.opacity(0.22), radius: 8, x: 0, y: 4)
            )
    }

    private var ledgerRules: some View {
        GeometryReader { geo in
            let step: CGFloat = 9
            Path { path in
                var y: CGFloat = step
                while y < geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += step
                }
            }
            .stroke(Palette.primary.opacity(0.07), lineWidth: 0.6)
            Path { path in
                path.move(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 10, y: geo.size.height))
            }
            .stroke(Palette.accent.opacity(0.45), lineWidth: 1.4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .allowsHitTesting(false)
    }
}
