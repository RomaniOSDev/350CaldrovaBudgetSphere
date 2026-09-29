import SwiftUI

struct NoInternetView: View {
    var onRetry: () -> Void
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            deskBackground

            Group {
                if isLandscape {
                    landscapeBody
                } else {
                    portraitBody
                }
            }
            .padding(.horizontal, isLandscape ? 32 : 24)
            .padding(.vertical, isLandscape ? 16 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private var portraitBody: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            iconBadge
            titleBlock
            Spacer(minLength: 0)
            retryButton
                .padding(.bottom, 8)
        }
    }

    private var landscapeBody: some View {
        HStack(alignment: .center, spacing: 28) {
            iconBadge
                .scaleEffect(0.92)

            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                    .frame(maxWidth: .infinity, alignment: .leading)

                retryButton
                    .frame(maxWidth: 240)
            }
            .frame(maxWidth: 420, alignment: .leading)
        }
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(Color.appSurface.opacity(0.95))
                .frame(width: isLandscape ? 96 : 108, height: isLandscape ? 96 : 108)
                .overlay(
                    Circle()
                        .stroke(Color.appAccent.opacity(0.35), lineWidth: 1.2)
                )

            Image(systemName: "wifi.slash")
                .font(.system(size: isLandscape ? 34 : 40, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var titleBlock: some View {
        VStack(alignment: isLandscape ? .leading : .center, spacing: 8) {
            Text("No Internet Connection")
                .font(.system(size: isLandscape ? 20 : 22, weight: .semibold, design: .rounded))
                .foregroundColor(.appPrimary)
                .multilineTextAlignment(isLandscape ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Please check your connection and try again.")
                .font(.system(size: isLandscape ? 14 : 15, weight: .regular, design: .rounded))
                .foregroundColor(.appPrimary.opacity(0.72))
                .multilineTextAlignment(isLandscape ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var retryButton: some View {
        Button(action: onRetry) {
            Text("Retry")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isLandscape ? 13 : 15)
                .background(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var deskBackground: some View {
        Color.appBackground
            .overlay {
                Image("BgLedger")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.22)
                    .allowsHitTesting(false)
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color.appBackground.opacity(0.7),
                        Color.appSurface.opacity(0.45),
                        Color.appBackground.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .ignoresSafeArea()
    }
}

#Preview {
    NoInternetView(onRetry: {})
}
