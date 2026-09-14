import SwiftUI

struct SphereRing<Center: View>: View {
    var progress: Double
    var size: CGFloat = 96
    var lineWidth: CGFloat = 8
    @ViewBuilder var center: () -> Center

    private var clamped: CGFloat {
        CGFloat(min(1, max(0, progress.isFinite ? progress : 0)))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.background, lineWidth: lineWidth + 4)
            Circle()
                .stroke(Palette.surface, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    LinearGradient(
                        colors: [Palette.primary, Palette.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Palette.primary.opacity(0.35), radius: 4, x: 0, y: 0)
            Circle()
                .stroke(Palette.accent.opacity(0.18), lineWidth: 1)
                .padding(lineWidth + 3)
            center()
        }
        .frame(width: size, height: size)
    }
}

extension SphereRing where Center == EmptyView {
    init(progress: Double, size: CGFloat = 96, lineWidth: CGFloat = 8) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.center = { EmptyView() }
    }
}
