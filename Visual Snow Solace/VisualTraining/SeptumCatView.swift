// SeptumCatView.swift
// Visual Snow Solace
//
// Septum (physiological diplopia) awareness exercise. The user holds a finger
// in front of their nose and looks past it at a far target, observing two
// "ghost" images of the finger. A stability indicator tracks how long the
// user maintains awareness. Includes a "Lost it — refocus" button that resets
// the streak counter.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SeptumCatView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Configuration
    @State private var durationMinutes: Double = 3
    @State private var hapticEnabled = true
    @State private var audioCue = false

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var streakTime: TimeInterval = 0
    @State private var bestStreak: TimeInterval = 0
    @State private var isStable = true // user hasn't tapped "lost it"
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    private var sessionDuration: TimeInterval {
        durationMinutes * 60
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                instructionsSection

                illustrationSection
                    .frame(height: 260)

                if isRunning {
                    streakDisplay

                    lostItButton
                }

                configurationSection
                    .disabled(isRunning)

                if isRunning {
                    sessionTimerLabel
                }

                startStopButton

                DisclaimerFooter()
            }
            .padding()
        }
        .navigationTitle("Septum Cat")
        .onDisappear { stop() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
        .alert("Take a Break", isPresented: $showBreakAlert) {
            Button("Continue") {}
            Button("Stop", role: .destructive) { stop() }
        } message: {
            Text("You have been exercising for 5 minutes. Consider resting your eyes.")
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.headline)

            Text("Hold your finger or a pen vertically in front of your nose, midway between your eyes. Look past it at a target on the wall. You should see two transparent 'ghost' images of your finger due to physiological diplopia — this is normal. Try to keep both ghost images visible and equal while focusing on the far target. Practice holding this awareness for 10–30 seconds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Illustration

    private var illustrationSection: some View {
        GeometryReader { geo in
            Canvas { context, size in
                drawIllustration(context: context, size: size)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Septum cat illustration. Two ghost finger images flanking a focus target. \(isStable ? "Stable" : "Lost focus, refocusing")")
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private func drawIllustration(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        // Background target circle (far focus point)
        let targetRadius: CGFloat = 16
        let targetRect = CGRect(
            x: centerX - targetRadius,
            y: centerY - targetRadius,
            width: targetRadius * 2,
            height: targetRadius * 2
        )
        context.stroke(
            Path(ellipseIn: targetRect),
            with: .color(.primary),
            lineWidth: 2
        )

        // Inner dot of target
        let innerDot: CGFloat = 4
        let innerRect = CGRect(
            x: centerX - innerDot,
            y: centerY - innerDot,
            width: innerDot * 2,
            height: innerDot * 2
        )
        context.fill(Path(ellipseIn: innerRect), with: .color(.primary))

        // Target label
        let targetLabel = Text("Focus target")
            .font(.caption2)
            .foregroundColor(.secondary)
        context.draw(
            context.resolve(targetLabel),
            at: CGPoint(x: centerX, y: centerY + targetRadius + 16),
            anchor: .center
        )

        // Stability ring around target
        if isRunning {
            let ringRadius = targetRadius + 6
            let ringRect = CGRect(
                x: centerX - ringRadius,
                y: centerY - ringRadius,
                width: ringRadius * 2,
                height: ringRadius * 2
            )
            context.stroke(
                Path(ellipseIn: ringRect),
                with: .color(isStable ? .green : .red),
                lineWidth: 2
            )
        }

        // Ghost finger images (two semi-transparent bars offset left and right)
        let fingerWidth: CGFloat = 10
        let fingerHeight: CGFloat = 100
        let ghostOffset: CGFloat = 40

        // Left ghost
        let leftFingerRect = CGRect(
            x: centerX - ghostOffset - fingerWidth / 2,
            y: centerY - fingerHeight / 2,
            width: fingerWidth,
            height: fingerHeight
        )
        context.fill(
            Path(roundedRect: leftFingerRect, cornerRadius: 3),
            with: .color(.gray.opacity(0.25))
        )

        // Right ghost
        let rightFingerRect = CGRect(
            x: centerX + ghostOffset - fingerWidth / 2,
            y: centerY - fingerHeight / 2,
            width: fingerWidth,
            height: fingerHeight
        )
        context.fill(
            Path(roundedRect: rightFingerRect, cornerRadius: 3),
            with: .color(.gray.opacity(0.25))
        )

        // Ghost labels
        let ghostLabel = Text("Ghost images")
            .font(.caption2)
            .foregroundColor(.secondary)
        context.draw(
            context.resolve(ghostLabel),
            at: CGPoint(x: centerX, y: centerY + fingerHeight / 2 + 16),
            anchor: .center
        )
    }

    // MARK: - Streak Display

    private var streakDisplay: some View {
        VStack(spacing: 4) {
            Text("Held: \(formatSeconds(streakTime))")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(isStable ? .green : .red)
                .contentTransition(.numericText())

            if bestStreak > 0 {
                Text("Best: \(formatSeconds(bestStreak))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak: \(Int(streakTime)) seconds. Best streak: \(Int(bestStreak)) seconds")
    }

    // MARK: - Lost It Button

    private var lostItButton: some View {
        Button {
            lostFocus()
        } label: {
            Label("Lost it — refocus", systemImage: "eye.slash")
        }
        .buttonStyle(.bordered)
        .tint(.orange)
        .accessibilityLabel("Lost focus, tap to reset streak and refocus")
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Duration")
                    .font(.subheadline)
                Spacer()
                Picker("Duration", selection: $durationMinutes) {
                    Text("1 min").tag(1.0)
                    Text("3 min").tag(3.0)
                    Text("5 min").tag(5.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .accessibilityLabel("Session duration picker")
            }

            Toggle("Haptic Feedback", isOn: $hapticEnabled)
                .font(.subheadline)
                .accessibilityLabel("Enable haptic feedback")

            Toggle("Audio Cue", isOn: $audioCue)
                .font(.subheadline)
                .accessibilityLabel("Enable audio cue")
        }
    }

    // MARK: - Session Timer

    private var sessionTimerLabel: some View {
        Text("Session: \(formatTime(elapsed))")
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel("Session time: \(Int(elapsed)) seconds")
    }

    // MARK: - Start / Stop

    private var startStopButton: some View {
        Button {
            if isRunning { stop() } else { start() }
        } label: {
            Text(isRunning ? "Stop" : "Begin Exercise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? "Stop septum cat exercise" : "Begin septum cat exercise")
    }

    private func start() {
        isRunning = true
        elapsed = 0
        streakTime = 0
        bestStreak = 0
        isStable = true
        breakAlertShown = false
    }

    private func stop() {
        isRunning = false
        elapsed = 0
        streakTime = 0
    }

    // MARK: - Logic

    private func tick() {
        elapsed += 0.1

        if elapsed >= sessionDuration {
            stop()
            return
        }

        if elapsed >= 300 && !breakAlertShown {
            breakAlertShown = true
            showBreakAlert = true
        }

        if isStable {
            streakTime += 0.1
            if streakTime > bestStreak {
                bestStreak = streakTime
            }
        }
    }

    private func lostFocus() {
        isStable = false
        streakTime = 0
        if hapticEnabled { triggerHaptic() }

        // Auto-recover after a brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard isRunning else { return }
            isStable = true
        }
    }

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return "\(s)s"
    }
}
