// PencilPushupsView.swift
// Visual Snow Solace
//
// Pencil push-up convergence exercise. An animated pencil shape moves along
// a horizontal axis from arm's length toward the nose and back. The user
// tracks the pencil tip, stopping when it doubles. Configurable rep target,
// movement speed, and haptic feedback at the near endpoint.

import SwiftUI
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

// MARK: - Movement Speed

enum PencilSpeed: String, CaseIterable, Identifiable {
    case slow = "Slow"
    case medium = "Medium"
    case fast = "Fast"

    var id: String { rawValue }

    /// Duration in seconds for one full near→far cycle.
    var cycleDuration: Double {
        switch self {
        case .slow:   return 8.0
        case .medium: return 5.0
        case .fast:   return 3.0
        }
    }
}

// MARK: - View

struct PencilPushupsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Configuration
    @State private var repTarget: Int = 15
    @State private var speed: PencilSpeed = .medium
    @State private var hapticEnabled = true
    @State private var audioCue = false

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var currentRep = 0
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false
    @State private var pencilProgress: CGFloat = 0 // 0 = far, 1 = near

    // Animation state
    @State private var movingInward = true

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                instructionsSection

                pencilDiagram
                    .frame(height: 180)

                if isRunning {
                    repCounter
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
        .navigationTitle("Pencil Pushups")
        .onDisappear { stop() }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
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

            Text("Hold a pencil at arm's length, tip pointing up, at eye level. Focus on the tip until you see it clearly as a single image. Slowly move it toward your nose, maintaining single clear focus. Stop when it doubles or blurs. Hold 2 seconds, then move it back out. Repeat 10–20 times per session.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Pencil Diagram

    private var pencilDiagram: some View {
        GeometryReader { geo in
            let size = geo.size
            Canvas { context, canvasSize in
                drawPencil(context: context, size: canvasSize)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pencil pushup diagram. Pencil at \(Int(pencilProgress * 100)) percent distance. Rep \(currentRep) of \(repTarget)")
            .onAppear { _ = size }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private func drawPencil(context: GraphicsContext, size: CGSize) {
        let midY = size.height * 0.45
        let leftX = size.width * 0.1   // far position
        let rightX = size.width * 0.85  // near position (closer to nose)
        let range = rightX - leftX

        // Current pencil X based on progress
        let pencilX = leftX + range * pencilProgress

        // Draw track line
        var trackPath = Path()
        trackPath.move(to: CGPoint(x: leftX, y: midY))
        trackPath.addLine(to: CGPoint(x: rightX, y: midY))
        context.stroke(trackPath, with: .color(.gray.opacity(0.4)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

        // Draw "nose" indicator at right edge
        let noseX = size.width * 0.92
        var nosePath = Path()
        nosePath.move(to: CGPoint(x: noseX - 6, y: midY - 10))
        nosePath.addLine(to: CGPoint(x: noseX, y: midY))
        nosePath.addLine(to: CGPoint(x: noseX - 6, y: midY + 10))
        context.stroke(nosePath, with: .color(.secondary), lineWidth: 1.5)

        // Draw pencil body (vertical rectangle + tip triangle)
        let pencilWidth: CGFloat = 8
        let pencilHeight: CGFloat = 60
        let pencilTop = midY - pencilHeight / 2

        // Body
        let bodyRect = CGRect(
            x: pencilX - pencilWidth / 2,
            y: pencilTop + 10,
            width: pencilWidth,
            height: pencilHeight - 10
        )
        context.fill(Path(bodyRect), with: .color(.yellow))
        context.stroke(Path(bodyRect), with: .color(.orange), lineWidth: 1)

        // Tip triangle
        var tipPath = Path()
        tipPath.move(to: CGPoint(x: pencilX - pencilWidth / 2, y: pencilTop + 10))
        tipPath.addLine(to: CGPoint(x: pencilX, y: pencilTop))
        tipPath.addLine(to: CGPoint(x: pencilX + pencilWidth / 2, y: pencilTop + 10))
        tipPath.closeSubpath()
        context.fill(tipPath, with: .color(.gray))

        // "Stop here" label near the near endpoint
        let labelText = Text("Stop here if it doubles")
            .font(.caption2)
            .foregroundColor(.secondary)
        context.draw(
            context.resolve(labelText),
            at: CGPoint(x: rightX - 20, y: midY + 45),
            anchor: .center
        )

        // Far label
        let farText = Text("Arm's length")
            .font(.caption2)
            .foregroundColor(.secondary)
        context.draw(
            context.resolve(farText),
            at: CGPoint(x: leftX + 30, y: midY + 45),
            anchor: .center
        )
    }

    // MARK: - Rep Counter

    private var repCounter: some View {
        Text("Rep \(currentRep) / \(repTarget)")
            .font(.title3.bold().monospacedDigit())
            .foregroundStyle(.primary)
            .accessibilityLabel("Rep \(currentRep) of \(repTarget)")
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Reps")
                    .font(.subheadline)
                Spacer()
                Picker("Rep target", selection: $repTarget) {
                    Text("10").tag(10)
                    Text("15").tag(15)
                    Text("20").tag(20)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .accessibilityLabel("Rep target picker")
            }

            HStack {
                Text("Speed")
                    .font(.subheadline)
                Spacer()
                Picker("Speed", selection: $speed) {
                    ForEach(PencilSpeed.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .accessibilityLabel("Movement speed picker")
            }

            Toggle("Haptic at Near Point", isOn: $hapticEnabled)
                .font(.subheadline)
                .accessibilityLabel("Enable haptic feedback at near endpoint")

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
        .accessibilityLabel(isRunning ? "Stop pencil pushups exercise" : "Begin pencil pushups exercise")
    }

    private func start() {
        isRunning = true
        elapsed = 0
        currentRep = 0
        pencilProgress = 0
        movingInward = true
        breakAlertShown = false
    }

    private func stop() {
        isRunning = false
        elapsed = 0
        pencilProgress = 0
    }

    // MARK: - Tick

    private func tick() {
        let dt: TimeInterval = 0.016
        elapsed += dt

        if elapsed >= 300 && !breakAlertShown {
            breakAlertShown = true
            showBreakAlert = true
        }

        // Move pencil
        let cycleTime = speed.cycleDuration
        let halfCycle = cycleTime / 2
        let progressDelta = CGFloat(dt / halfCycle)

        if movingInward {
            pencilProgress += progressDelta
            if pencilProgress >= 1.0 {
                pencilProgress = 1.0
                movingInward = false
                if hapticEnabled { triggerHaptic() }
            }
        } else {
            pencilProgress -= progressDelta
            if pencilProgress <= 0.0 {
                pencilProgress = 0.0
                movingInward = true
                currentRep += 1

                if currentRep >= repTarget {
                    stop()
                    return
                }
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
