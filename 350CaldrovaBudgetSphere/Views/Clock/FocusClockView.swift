import SwiftUI
import UIKit

struct FocusClockView: View {
    @EnvironmentObject private var store: LedgerStore

    private var isFirstRun: Bool {
        store.sessionHistory.isEmpty
            && !store.timerRunning
            && store.remainingSnapshot >= store.currentCycleSeconds() - 0.5
            && !store.isBreak
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GoldBanner(imageName: "BannerTimer")

                if isFirstRun {
                    LedgerPlate {
                        VStack(spacing: 10) {
                            Image(systemName: "hourglass.tophalf.fill")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(Palette.primary)
                            Text("Start your focus journey")
                                .font(.system(.title3, design: .serif).weight(.semibold))
                                .foregroundColor(Palette.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }

                if store.showWellDone {
                    LedgerPlate {
                        Text("Well done!")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundColor(Palette.primary)
                            .frame(maxWidth: .infinity)
                    }
                }

                clockPlate
                controls
                durationSliders
                sessionLedger
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private var clockPlate: some View {
        LedgerPlate {
            VStack(spacing: 14) {
                TimelineView(.periodic(from: .now, by: 0.25)) { context in
                    let left = store.remaining(at: context.date)
                    let progress = store.progress(at: context.date)
                    HStack(spacing: 18) {
                        SphereRing(progress: progress, size: 124, lineWidth: 10) {
                            VStack(spacing: 2) {
                                Text(clockLabel(left))
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundColor(Palette.primary)
                                    .monospacedDigit()
                                Text(store.isBreak ? "BREAK" : "FOCUS")
                                    .font(.system(size: 10, weight: .bold, design: .serif))
                                    .tracking(1.4)
                                    .foregroundColor(Palette.accent)
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text(store.timerRunning ? "In motion" : "Held")
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Palette.primary)
                            Text("\(store.completedSessionsToday)")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(Palette.accent)
                            Text("sessions today")
                                .font(.caption)
                                .foregroundColor(Palette.primary.opacity(0.8))
                            let streak = store.focusStreak()
                            if streak > 0 {
                                Text("\(streak)-day streak")
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .foregroundColor(Palette.primary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            if store.timerRunning {
                goldAction("Pause", symbol: "pause.fill") {
                    store.pauseTimer()
                }
            } else if store.remaining() > 0 && store.remaining() < store.currentCycleSeconds() - 0.4 {
                goldAction("Resume", symbol: "play.fill") {
                    store.resumeTimer()
                }
            } else {
                goldAction(store.isBreak ? "Start Break" : "Start Focus", symbol: "play.fill") {
                    store.startTimer()
                }
            }
        }
    }

    private var durationSliders: some View {
        LedgerPlate {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Focus")
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                            .foregroundColor(Palette.primary)
                        Spacer()
                        Text("\(store.focusDurationMin) min")
                            .font(.system(.subheadline, design: .monospaced).weight(.bold))
                            .foregroundColor(Palette.accent)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(store.focusDurationMin) },
                            set: { store.setFocusDuration(Int($0.rounded())) }
                        ),
                        in: 15...60,
                        step: 1
                    )
                    .tint(Palette.primary)
                    .disabled(store.timerRunning)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Break")
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                            .foregroundColor(Palette.primary)
                        Spacer()
                        Text("\(store.breakDurationMin) min")
                            .font(.system(.subheadline, design: .monospaced).weight(.bold))
                            .foregroundColor(Palette.accent)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(store.breakDurationMin) },
                            set: { store.setBreakDuration(Int($0.rounded())) }
                        ),
                        in: 5...20,
                        step: 1
                    )
                    .tint(Palette.accent)
                    .disabled(store.timerRunning)
                }

                if !store.durationNotice.isEmpty {
                    Text(store.durationNotice)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(Palette.accent)
                }
            }
        }
    }

    private var sessionLedger: some View {
        Group {
            if !store.sessionHistory.isEmpty {
                LedgerPlate {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SESSION LEDGER")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .tracking(1.2)
                            .foregroundColor(Palette.accent)
                        ForEach(Array(store.sessionHistory.prefix(12).enumerated()), id: \.offset) { _, stamp in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(Palette.primary)
                                Text(Self.stamp.string(from: stamp))
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(Palette.primary)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    private func goldAction(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title)
                    .font(.system(.subheadline, design: .serif).weight(.bold))
            }
            .foregroundColor(Palette.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Palette.primary, Palette.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Palette.primary.opacity(0.35), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    private func clockLabel(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private static let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
