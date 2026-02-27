// BarrelCardsView.swift
// Visual Snow Solace
//
// Barrel card convergence exercise. Displays a series of concentric rings
// representing distance zones on a barrel card. The user focuses on each ring
// from farthest to nearest. The active ring is highlighted; a "Hold" / "Shift"
// label tracks progress. Configurable dwell time per ring with optional haptic
// and audio cues on transitions.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BarrelCardsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Configuration
    @State private var durationMinutes: Double = 3
    @State private var dwellTime: Double = 5 // seconds per ring
    @State private var hapticEnabled = true
    @State private var audioCue = false

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var activeRing: Int = 0 // 0 = farthest, 4 = nearest
    @State private var ringElapsed: TimeInterval = 0
    @State private var isTransitioning = false
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false

    private let ringCount = 5

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
                    .frame(height: 320)

                if isRunning {
                    statusLabel
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
        .navigationTitle("Barrel Cards")
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

            Text("Hold a barrel card (or use the on-screen guide) lengthwise against your nose, with the series of rings visible. Focus on the farthest ring until it appears single and clear. Hold for 5 seconds, then shift focus to the next closer ring. Work inward ring by ring. If a ring doubles, hold until it merges before moving on.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Ring Diagram

    private var ringDiagram: some View {
        GeometryReader { geo in
            Canvas { context, size in
                drawRings(context: context, size: size)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Barrel card diagram. Focused on ring \(activeRing + 1) of \(ringCount). \(isTransitioning ? "Shifting focus" : "Hold focus")")
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private func drawRings(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2

        // Rings arranged vertically: top = farthest (smallest), bottom = nearest (largest)
        let topY = size.height * 0.08
        let bottomY = size.height * 0.88
        let verticalSpacing = (bottomY - topY) / CGFloat(ringCount - 1)

        for i in 0..<ringCount {
            let ringY = topY + CGFloat(i) * verticalSpacing
            let ringRadius = 20 + CGFloat(i) * 12 // increasing size top to bottom
            let isActive = i == activeRing

            // Outer ring
            let outerRect = CGRect(
                x: centerX - ringRadius,
                y: ringY - ringRadius,
                width: ringRadius * 2,
                height: ringRadius * 2
            )
            context.stroke(
                Path(ellipseIn: outerRect),
                with: .color(isActive ? .blue : .gray.opacity(0.4)),
                lineWidth: isActive ? 3 : 1.5
            )

            // Inner ring (smaller concentric)
            let innerRadius = ringRadius * 0.55
            let innerRect = CGRect(
                x: centerX - innerRadius,
                y: ringY - innerRadius,
                width: innerRadius * 2,
                height: innerRadius * 2
            )
            context.stroke(
                Path(ellipseIn: innerRect),
                with: .color(isActive ? .blue.opacity(0.7) : .gray.opacity(0.3)),
                lineWidth: isActive ? 2 : 1
            )

            // Fill active ring center dot
            if isActive {
                let dotRadius: CGFloat = 4
                let dotRect = CGRect(
                    x: centerX - dotRadius,
                    y: ringY - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
                context.fill(Path(ellipseIn: dotRect), with: .color(.blue))
            }

            // Ring number label
            let labelText = Text("Ring \(i + 1)")
                .font(.caption2)
                .foregroundColor(isActive ? .blue : .secondary)
            context.draw(
                context.resolve(labelText),
                at: CGPoint(x: centerX + ringRadius + 30, y: ringY),
                anchor: .leading
            )
        }

        // Distance labels
        let farText = Text("Farthest")
            .font(.caption2)
            .foregroundColor(.secondary)
        context.draw(
            context.resolve(farText),
            at: CGPoint(x: size.width * 0.12, y: topY),
            anchor: .center
        )

        let nearText = Text("Nearest")
            .font(.caption2)
            .foregroundColor(.secondary)
        context.draw(
            context.resolve(nearText),
            at: CGPoint(x: size.width * 0.12, y: bottomY),
            anchor: .center
        )

        // Progress arrow along the left side
        if isRunning {
            let progressY = topY + CGFloat(activeRing) * verticalSpacing
            var arrowPath = Path()
            let arrowX = size.width * 0.06
            arrowPath.move(to: CGPoint(x: arrowX, y: progressY - 6))
            arrowPath.addLine(to: CGPoint(x: arrowX + 6, y: progressY))
            arrowPath.addLine(to: CGPoint(x: arrowX, y: progressY + 6))
            context.fill(arrowPath, with: .color(.blue))
        }
    }

    // MARK: - Status Label

    private var statusLabel: some View {
        Text(isTransitioning ? "Shift →" : "Hold…")
            .font(.title3.bold())
            .foregroundStyle(isTransitioning ? .orange : .blue)
            .contentTransition(.numericText())
            .accessibilityLabel(isTransitioning ? "Shift focus to next ring" : "Hold focus on current ring")
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

            HStack {
                Text("Dwell Time")
                    .font(.subheadline)
                Spacer()
                Picker("Dwell time per ring", selection: $dwellTime) {
                    Text("3s").tag(3.0)
                    Text("5s").tag(5.0)
                    Text("8s").tag(8.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .accessibilityLabel("Dwell time per ring")
            }

            Toggle("Haptic on Transition", isOn: $hapticEnabled)
                .font(.subheadline)
                .accessibilityLabel("Enable haptic feedback on ring transition")

            Toggle("Audio Cue", isOn: $audioCue)
                .font(.subheadline)
                .accessibilityLabel("Enable audio chime on ring transition")
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
        .accessibilityLabel(isRunning ? "Stop barrel cards exercise" : "Begin barrel cards exercise")
    }

    private func start() {
        isRunning = true
        elapsed = 0
        activeRing = 0
        ringElapsed = 0
        isTransitioning = false
        breakAlertShown = false
    }

    private func stop() {
        isRunning = false
        elapsed = 0
        activeRing = 0
        ringElapsed = 0
        isTransitioning = false
    }

    // MARK: - Tick

    private func tick() {
        elapsed += 0.1
        ringElapsed += 0.1

        if elapsed >= sessionDuration {
            stop()
            return
        }

        if elapsed >= 300 && !breakAlertShown {
            breakAlertShown = true
            showBreakAlert = true
        }

        if ringElapsed >= dwellTime {
            // Brief transition indicator
            isTransitioning = true

            // Advance to next ring (wrap around)
            activeRing = (activeRing + 1) % ringCount
            ringElapsed = 0
            if hapticEnabled { triggerHaptic() }

            // Clear transition flag after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTransitioning = false
            }
        }
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
}
