import SwiftUI

struct LoadingAmbientField: View {
    @State private var drift = false

    var body: some View {
        Color.appBackground
            .overlay {
                Image("BgLedger")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.22)
                    .allowsHitTesting(false)
            }
            .overlay {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.appBackground.opacity(0.55),
                            Color.appSurface.opacity(0.28),
                            Color.appBackground.opacity(0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    RadialGradient(
                        colors: [
                            Color.appPrimary.opacity(0.28),
                            Color.appAccent.opacity(0.1),
                            .clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.3),
                        startRadius: 10,
                        endRadius: 320
                    )

                    Ellipse()
                        .fill(Color.appPrimary.opacity(0.16))
                        .frame(width: 260, height: 160)
                        .blur(radius: 64)
                        .offset(x: drift ? 24 : -20, y: drift ? -140 : -100)

                    Ellipse()
                        .fill(Color.appAccent.opacity(0.12))
                        .frame(width: 240, height: 200)
                        .blur(radius: 58)
                        .offset(x: drift ? -36 : 30, y: drift ? 210 : 170)

                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .stroke(Color.appPrimary.opacity(0.1 + Double(index % 3) * 0.04), lineWidth: 1)
                            .frame(width: CGFloat(70 + index * 18), height: CGFloat(70 + index * 18))
                            .offset(
                                x: ringX(index) + (drift ? 5 : -5),
                                y: ringY(index) + (drift ? -6 : 6)
                            )
                    }
                }
            }
            .clipped()
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeInOut(duration: 5.2).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
    }

    private func ringX(_ index: Int) -> CGFloat {
        let values: [CGFloat] = [-120, 110, -70, 140, -30]
        return values[index % values.count]
    }

    private func ringY(_ index: Int) -> CGFloat {
        let values: [CGFloat] = [-200, -140, 60, 150, 210]
        return values[index % values.count]
    }
}

struct LoadingSphereMark: View {
    var compact: Bool = false
    @State private var pulse = false
    @State private var progress: Double = 0.18

    private var outerSize: CGFloat { compact ? 112 : 148 }
    private var ringSize: CGFloat { compact ? 100 : 132 }
    private var iconSize: CGFloat { compact ? 26 : 32 }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appPrimary.opacity(0.22),
                            Color.appSurface,
                            Color.appBackground.opacity(0.95)
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: outerSize * 0.58
                    )
                )
                .frame(width: outerSize, height: outerSize)
                .shadow(color: Color.appPrimary.opacity(pulse ? 0.5 : 0.22), radius: pulse ? 20 : 10)

            SphereRing(progress: progress, size: ringSize, lineWidth: compact ? 7 : 9) {
                VStack(spacing: compact ? 4 : 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(pulse ? 1.06 : 0.96)

                    Text("SPHERE")
                        .font(.system(size: compact ? 9 : 10, weight: .bold, design: .rounded))
                        .tracking(2.6)
                        .foregroundStyle(Color.appPrimary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                progress = 0.86
            }
        }
    }
}

struct LoadingHeroPlate: View {
    var landscape: Bool = false
    @State private var glow = false

    private var plateHeight: CGFloat { landscape ? 168 : 236 }
    private var plateMaxWidth: CGFloat { landscape ? 220 : 280 }
    private var titleSize: CGFloat { landscape ? 22 : 26 }

    var body: some View {
        VStack(spacing: landscape ? 12 : 20) {
            Text("CALDROVA")
                .font(.system(size: landscape ? 11 : 13, weight: .semibold, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.appAccent)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface, Color.appBackground.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(ledgerRules)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.appPrimary.opacity(0.85), lineWidth: 1.2)
                    )
                    .shadow(color: Color.appPrimary.opacity(glow ? 0.38 : 0.18), radius: glow ? 24 : 12, y: 8)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.appAccent)
                        .frame(width: 4)

                    Spacer(minLength: 0)

                    LoadingSphereMark(compact: landscape)
                        .padding(.vertical, landscape ? 14 : 26)

                    Spacer(minLength: 0)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .frame(maxWidth: plateMaxWidth)
            .frame(height: plateHeight)
            .frame(maxWidth: .infinity)

            VStack(spacing: landscape ? 6 : 8) {
                Text("BUDGET SPHERE")
                    .font(.system(size: titleSize, weight: .semibold, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(Color.appPrimary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("Duties, spend, and a clear gold focus.")
                    .font(.system(size: landscape ? 13 : 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.appPrimary.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
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
            .stroke(Color.appPrimary.opacity(0.07), lineWidth: 0.6)

            Path { path in
                path.move(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 10, y: geo.size.height))
            }
            .stroke(Color.appAccent.opacity(0.45), lineWidth: 1.4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .allowsHitTesting(false)
    }
}

struct LoadingProgressBar: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appSurface.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent, Color.appPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(width * 0.36, 34))
                    .offset(x: phase * (width * 0.64))
                    .shadow(color: Color.appPrimary.opacity(0.55), radius: 8, y: 0)
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}

struct LoadingStatusLine: View {
    @State private var step = 0

    private let lines = [
        "Opening the budget sphere",
        "Balancing the gold ledger",
        "Tuning focus and spend"
    ]

    var body: some View {
        Text(lines[step % lines.count])
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(Color.appPrimary.opacity(0.8))
            .multilineTextAlignment(.center)
            .id(step)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_700_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.32)) {
                        step = (step + 1) % lines.count
                    }
                }
            }
    }
}

struct LoadingView: View {
    @State private var appeared = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            LoadingAmbientField()

            Group {
                if isLandscape {
                    landscapeContent
                } else {
                    portraitContent
                }
            }
            .padding(.horizontal, isLandscape ? 28 : 24)
            .padding(.vertical, isLandscape ? 12 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.72, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private var portraitContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            LoadingHeroPlate(landscape: false)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.92)
                .offset(y: appeared ? 0 : 18)

            progressBlock
                .padding(.top, 28)

            Spacer(minLength: 0)
        }
    }

    private var landscapeContent: some View {
        HStack(alignment: .center, spacing: 24) {
            LoadingHeroPlate(landscape: true)
                .frame(maxWidth: 320)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.94)
                .offset(x: appeared ? 0 : -16)

            VStack(spacing: 16) {
                Spacer(minLength: 0)
                progressBlock
                Spacer(minLength: 0)
            }
            .frame(maxWidth: 220)
            .opacity(appeared ? 1 : 0)
            .offset(x: appeared ? 0 : 16)
        }
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var progressBlock: some View {
        VStack(spacing: 14) {
            LoadingProgressBar()
                .frame(maxWidth: isLandscape ? 200 : 168)
                .opacity(appeared ? 1 : 0)

            LoadingStatusLine()
                .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Portrait") {
    LoadingView()
}

#Preview("Landscape") {
    LoadingView()
        .previewInterfaceOrientation(.landscapeLeft)
}
