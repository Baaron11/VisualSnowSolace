// BrockStringView.swift
// Visual Snow Solace
//
// Brock String convergence exercise. Displays a horizontal string diagram
// with three beads at near, middle, and far positions. The user focuses on
// each bead in turn; the active bead pulses and a convergence shape (V, X,
// or reversed V) is drawn beneath it. Haptic pacing cues the user to shift
// focus at a configurable interval.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BrockStringView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Configuration
    @State private var durationMinutes: Double = 3
    @State private var hapticPacing = true
    @State private var audioCue = false
    @State private var pacingInterval: Double = 5 // seconds between focus shifts

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var focusedBead: Int = 0 // 0 = near, 1 = middle, 2 = far
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false
    @State private var timeSinceLastShift: TimeInterval = 0
    @State private var pulseScale: CGFloat = 1.0

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    private var sessionDuration: TimeInterval {
        durationMinutes * 60
    }

    private let beadColors: [Color] = [.red, .green, .blue]
    private let beadLabels = ["Near (1 ft)", "Middle (5 ft)", "Far (9 ft)"]
    private let convergenceLabels = ["V shape", "X shape", "V reversed"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                instructionsSection

                diagramSection
                    .frame(height: 200)

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
        .navigationTitle("Brock String")
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

            Text("Attach a string (about 10 feet) to a fixed point at eye level. Place beads at 1 ft, 5 ft, and 9 ft. Hold the far end to your nose. Focus on the nearest bead — you should see two strings forming a V. Move focus to the middle bead (X shape), then the far bead (V pointing away). If you see only one string at any point, blink and refocus.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Diagram

    private var diagramSection: some View {
        GeometryReader { geo in
            let size = geo.size
            Canvas { context, canvasSize in
                drawStringDiagram(context: context, size: canvasSize)
            }
            .onAppear { _ = size }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Brock string diagram. Focused on \(beadLabels[focusedBead]) bead, expecting \(convergenceLabels[focusedBead])")
            .onTapGesture { location in
                handleBeadTap(at: location, in: size)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private func drawStringDiagram(context: GraphicsContext, size: CGSize) {
        let midY = size.height * 0.4
        let leftX = size.width * 0.1
        let rightX = size.width * 0.9
        let stringLength = rightX - leftX

        // Draw the string line
        var stringPath = Path()
        stringPath.move(to: CGPoint(x: leftX, y: midY))
        stringPath.addLine(to: CGPoint(x: rightX, y: midY))
        context.stroke(stringPath, with: .color(.gray), lineWidth: 2)

        // Bead positions: near (left), middle (center), far (right)
        let beadPositions: [CGFloat] = [
            leftX + stringLength * 0.1,
            leftX + stringLength * 0.5,
            leftX + stringLength * 0.9
        ]

        // Draw convergence shape beneath active bead
        let activeX = beadPositions[focusedBead]
        let chevronY = midY + 30
        let chevronSpread: CGFloat = 30

        var chevronPath = Path()
        switch focusedBead {
        case 0: // V shape (converging toward near)
            chevronPath.move(to: CGPoint(x: activeX - chevronSpread, y: chevronY + 20))
            chevronPath.addLine(to: CGPoint(x: activeX, y: chevronY))
            chevronPath.addLine(to: CGPoint(x: activeX + chevronSpread, y: chevronY + 20))
        case 1: // X shape
            chevronPath.move(to: CGPoint(x: activeX - chevronSpread, y: chevronY))
            chevronPath.addLine(to: CGPoint(x: activeX + chevronSpread, y: chevronY + 20))
            chevronPath.move(to: CGPoint(x: activeX + chevronSpread, y: chevronY))
            chevronPath.addLine(to: CGPoint(x: activeX - chevronSpread, y: chevronY + 20))
        default: // V reversed (diverging from far)
            chevronPath.move(to: CGPoint(x: activeX - chevronSpread, y: chevronY))
            chevronPath.addLine(to: CGPoint(x: activeX, y: chevronY + 20))
            chevronPath.addLine(to: CGPoint(x: activeX + chevronSpread, y: chevronY))
        }
        context.stroke(chevronPath, with: .color(.orange), lineWidth: 2)

        // Draw beads
        for (index, posX) in beadPositions.enumerated() {
            let isActive = index == focusedBead
            let radius: CGFloat = isActive ? 14 * pulseScale : 12
            let beadRect = CGRect(
                x: posX - radius,
                y: midY - radius,
                width: radius * 2,
                height: radius * 2
            )

            let color = beadColors[index]
            context.fill(
                Path(ellipseIn: beadRect),
                with: .color(isActive ? color : color.opacity(0.5))
            )

            // Focus point label
            let labelY = midY + 60
            let text = Text(beadLabels[index])
                .font(.caption2)
                .foregroundColor(.secondary)
            context.draw(
                context.resolve(text),
                at: CGPoint(x: posX, y: labelY),
                anchor: .center
            )
        }
    }

    private func handleBeadTap(at location: CGPoint, in size: CGSize) {
        let leftX = size.width * 0.1
        let stringLength = size.width * 0.8
        let beadPositions: [CGFloat] = [
            leftX + stringLength * 0.1,
            leftX + stringLength * 0.5,
            leftX + stringLength * 0.9
        ]

        var closestIndex = 0
        var closestDist = CGFloat.infinity
        for (index, posX) in beadPositions.enumerated() {
            let dist = abs(location.x - posX)
            if dist < closestDist {
                closestDist = dist
                closestIndex = index
            }
        }

        focusedBead = closestIndex
        timeSinceLastShift = 0
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
            // Duration picker
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

            // Pacing interval
            HStack {
                Text("Pacing")
                    .font(.subheadline)
                Spacer()
                Picker("Pacing interval", selection: $pacingInterval) {
                    Text("3s").tag(3.0)
                    Text("5s").tag(5.0)
                    Text("8s").tag(8.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .accessibilityLabel("Haptic pacing interval")
            }

            Toggle("Haptic Pacing", isOn: $hapticPacing)
                .font(.subheadline)
                .accessibilityLabel("Enable haptic pacing")

            Toggle("Audio Cue", isOn: $audioCue)
                .font(.subheadline)
                .accessibilityLabel("Enable audio cue on focus shift")
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
        .accessibilityLabel(isRunning ? "Stop brock string exercise" : "Begin brock string exercise")
    }

    // MARK: - Logic

    private func start() {
        isRunning = true
        elapsed = 0
        timeSinceLastShift = 0
        focusedBead = 0
        breakAlertShown = false
        startPulse()
    }

    private func stop() {
        isRunning = false
        elapsed = 0
        timeSinceLastShift = 0
        pulseScale = 1.0
    }

    private func tick() {
        elapsed += 0.1
        timeSinceLastShift += 0.1

        if elapsed >= sessionDuration {
            stop()
            return
        }

        if elapsed >= 300 && !breakAlertShown {
            breakAlertShown = true
            showBreakAlert = true
        }

        // Auto-advance bead focus based on pacing interval
        if timeSinceLastShift >= pacingInterval {
            timeSinceLastShift = 0
            focusedBead = (focusedBead + 1) % 3
            if hapticPacing { triggerHaptic() }
            startPulse()
        }
    }

    private func startPulse() {
        guard !reduceMotion else { return }
        pulseScale = 1.0
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
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
