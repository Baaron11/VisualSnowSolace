// LifesaverView.swift
// Visual Snow Solace
//
// Lifesaver (free-fusion) exercise. Displays two identical ring shapes side
// by side. The user crosses their eyes slightly until a third fused ring
// appears between them. A spacing slider adjusts ring separation, a contrast
// toggle aids visibility, and a hold timer tracks how long fusion is maintained
// after the user taps "I see it."

import SwiftUI
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

struct LifesaverView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Configuration
    @State private var durationMinutes: Double = 3
    @State private var ringSpacing: CGFloat = 120 // 80–160pt
    @State private var highContrast = false
    @State private var hapticEnabled = true
    @State private var audioCue = false

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var holdTime: TimeInterval = 0
    @State private var isFused = false // user tapped "I see it"
    @State private var ghostOpacity: Double = 0
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

                ringDiagram
                    .frame(height: 240)

                if isRunning {
                    fusionControls

                    if isFused {
                        holdTimerDisplay
                    }
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
        .navigationTitle("Lifesaver")
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

            Text("Print or view two identical circles side by side (the on-screen guide shows these). Hold the screen at arm's length. Slowly cross your eyes slightly until a third circle appears in the center — this is the fused image. Try to bring it into clear focus and hold it. Once clear, look for a three-dimensional quality in the center circle. Hold for 5–10 seconds, then relax.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Ring Diagram

    private var ringDiagram: some View {
        GeometryReader { geo in
            Canvas { context, size in
                drawLifesaverRings(context: context, size: size)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Two lifesaver rings side by side. Spacing \(Int(ringSpacing)) points. \(isFused ? "Fusion detected, holding" : "Look for the third ring in the center")")
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private func drawLifesaverRings(context: GraphicsContext, size: CGSize) {
        let centerY = size.height * 0.45
        let centerX = size.width / 2

        let outerRadius: CGFloat = 36
        let innerRadius: CGFloat = 20

        let halfSpacing = ringSpacing / 2
        let leftX = centerX - halfSpacing
        let rightX = centerX + halfSpacing

        let outerColor: Color = highContrast ? .red : .red.opacity(0.8)
        let innerColor: Color = highContrast ? .white : .white.opacity(0.9)

        // Draw left ring
        drawRing(
            context: context,
            center: CGPoint(x: leftX, y: centerY),
            outerRadius: outerRadius,
            innerRadius: innerRadius,
            outerColor: outerColor,
            innerColor: innerColor
        )

        // Draw right ring
        drawRing(
            context: context,
            center: CGPoint(x: rightX, y: centerY),
            outerRadius: outerRadius,
            innerRadius: innerRadius,
            outerColor: outerColor,
            innerColor: innerColor
        )

        // Draw ghost (fused) ring in center
        if isRunning && ghostOpacity > 0 {
            let ghostOuterColor = outerColor.opacity(ghostOpacity)
            let ghostInnerColor = innerColor.opacity(ghostOpacity)
            drawRing(
                context: context,
                center: CGPoint(x: centerX, y: centerY),
                outerRadius: outerRadius,
                innerRadius: innerRadius,
                outerColor: ghostOuterColor,
                innerColor: ghostInnerColor
            )
        }

        // Hint text below
        let hintText = Text("A third circle should appear here \u{2191}")
            .font(.caption2)
            .foregroundColor(.secondary)
        context.draw(
            context.resolve(hintText),
            at: CGPoint(x: centerX, y: centerY + outerRadius + 24),
            anchor: .center
        )
    }

    private func drawRing(
        context: GraphicsContext,
        center: CGPoint,
        outerRadius: CGFloat,
        innerRadius: CGFloat,
        outerColor: Color,
        innerColor: Color
    ) {
        // Outer filled circle
        let outerRect = CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        )
        context.fill(Path(ellipseIn: outerRect), with: .color(outerColor))

        // Inner "hole" circle
        let innerRect = CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        )
        context.fill(Path(ellipseIn: innerRect), with: .color(innerColor))
    }

    // MARK: - Fusion Controls

    private var fusionControls: some View {
        VStack(spacing: 12) {
            if !isFused {
                Button {
                    startFusion()
                } label: {
                    Label("I see it", systemImage: "eye")
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .accessibilityLabel("Tap when you see the third fused ring")
            } else {
                Button {
                    releaseFusion()
                } label: {
                    Label("Lost it", systemImage: "eye.slash")
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .accessibilityLabel("Tap when you lose the fused ring")
            }

            // Spacing slider (always adjustable during session)
            VStack(alignment: .leading, spacing: 4) {
                Text("Ring Spacing: \(Int(ringSpacing))pt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Slider(value: $ringSpacing, in: 80...160)
                    .accessibilityLabel("Ring spacing, \(Int(ringSpacing)) points")
            }
        }
    }

    // MARK: - Hold Timer

    private var holdTimerDisplay: some View {
        Text("Hold: \(formatSeconds(holdTime))")
            .font(.title3.bold().monospacedDigit())
            .foregroundStyle(.green)
            .contentTransition(.numericText())
            .accessibilityLabel("Fusion held for \(Int(holdTime)) seconds")
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

            Toggle("High Contrast", isOn: $highContrast)
                .font(.subheadline)
                .accessibilityLabel("High contrast mode for easier fusion")

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
        .accessibilityLabel(isRunning ? "Stop lifesaver exercise" : "Begin lifesaver exercise")
    }

    private func start() {
        isRunning = true
        elapsed = 0
        holdTime = 0
        isFused = false
        breakAlertShown = false

        // Animate ghost ring appearance
        if reduceMotion {
            ghostOpacity = 0.85
        } else {
            ghostOpacity = 0
            withAnimation(.easeIn(duration: 1.5)) {
                ghostOpacity = 0.85
            }
        }
    }

    private func stop() {
        isRunning = false
        elapsed = 0
        holdTime = 0
        isFused = false
        ghostOpacity = 0
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

        if isFused {
            holdTime += 0.1
        }
    }

    private func startFusion() {
        isFused = true
        holdTime = 0
        if hapticEnabled { triggerHaptic() }
    }

    private func releaseFusion() {
        isFused = false
        holdTime = 0
        if hapticEnabled { triggerHaptic() }
    }

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
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
