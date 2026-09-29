import SwiftUI

struct NotificationPermissionView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void
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
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            iconSection
            textSection
            buttonsSection
            Spacer(minLength: 0)
        }
    }

    private var landscapeBody: some View {
        HStack(alignment: .center, spacing: 28) {
            iconSection
                .scaleEffect(0.9)

            VStack(alignment: .leading, spacing: 16) {
                textSection
                    .frame(maxWidth: .infinity, alignment: .leading)
                buttonsSection
                    .frame(maxWidth: 320)
            }
            .frame(maxWidth: 440, alignment: .leading)
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        Color.appSurface.opacity(0.4),
                        Color.appBackground.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .ignoresSafeArea()
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.appSurface.opacity(0.95))
                .frame(width: isLandscape ? 96 : 112, height: isLandscape ? 96 : 112)
                .overlay(
                    Circle()
                        .stroke(Color.appAccent.opacity(0.4), lineWidth: 1.2)
                )

            Image(systemName: "bell.badge.fill")
                .font(.system(size: isLandscape ? 36 : 44, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var textSection: some View {
        VStack(alignment: isLandscape ? .leading : .center, spacing: 12) {
            Text("Enable Notifications")
                .font(.system(size: isLandscape ? 20 : 22, weight: .semibold, design: .rounded))
                .foregroundColor(.appPrimary)
                .multilineTextAlignment(isLandscape ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Stay updated with important news and bonus. You can change this later in Settings.")
                .font(.system(size: isLandscape ? 14 : 15, weight: .regular, design: .rounded))
                .foregroundColor(.appPrimary.opacity(0.72))
                .multilineTextAlignment(isLandscape ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: isLandscape ? .leading : .center)
    }

    private var buttonsSection: some View {
        VStack(spacing: 14) {
            Button(action: onAccept) {
                Text("Enable")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isLandscape ? 14 : 16)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onDecline) {
                Text("Not Now")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.appPrimary.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isLandscape ? 12 : 14)
                    .background(Color.appSurface.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Notification Permission") {
    NotificationPermissionView(onAccept: {}, onDecline: {})
}
