// PencilPushupsView.swift
// Visual Snow Solace
//
// Pencil push-up convergence exercise. An animated pencil shape moves along
// a horizontal axis from arm's length toward the nose and back. The user
// tracks the pencil tip, stopping when it doubles. Configurable rep target,
// movement speed, and haptic feedback at the near endpoint.

import SwiftUI
import Foundation
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

    var localizedName: String {
        switch self {
        case .slow:   return NSLocalizedString("pencilPushups.speed.slow", comment: "Slow speed")
        case .medium: return NSLocalizedString("pencilPushups.speed.medium", comment: "Medium speed")
        case .fast:   return NSLocalizedString("pencilPushups.speed.fast", comment: "Fast speed")
        }
    }

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
        .navigationTitle(NSLocalizedString("pencilPushups.title", comment: "Pencil Pushups navigation title"))
        .onDisappear { stop() }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
        .alert(NSLocalizedString("pencilPushups.breakAlert.title", comment: "Break alert title"), isPresented: $showBreakAlert) {
            Button(NSLocalizedString("pencilPushups.breakAlert.continue", comment: "Continue button")) {}
            Button(NSLocalizedString("pencilPushups.breakAlert.stop", comment: "Stop button"), role: .destructive) { stop() }
        } message: {
            Text(NSLocalizedString("pencilPushups.breakAlert.message", comment: "Break alert message"))
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("pencilPushups.instructions.title", comment: "Instructions heading"))
                .font(.headline)

            Text(NSLocalizedString("pencilPushups.instructions.body", comment: "Pencil pushups exercise instructions"))
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
            .accessibilityLabel(String(format: NSLocalizedString("pencilPushups.diagram.accessibility", comment: "Pencil pushup diagram accessibility"), Int(pencilProgress * 100), currentRep, repTarget))
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
        let labelText = Text(NSLocalizedString("pencilPushups.diagram.stopHere", comment: "Stop here if it doubles label"))
            .font(.caption2)
            .foregroundColor(.secondary)
        context.draw(
            context.resolve(labelText),
            at: CGPoint(x: rightX - 20, y: midY + 45),
            anchor: .center
        )

        // Far label
        let farText = Text(NSLocalizedString("pencilPushups.diagram.armsLength", comment: "Arm's length label"))
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
        Text(String(format: NSLocalizedString("pencilPushups.rep", comment: "Rep counter"), currentRep, repTarget))
            .font(.title3.bold().monospacedDigit())
            .foregroundStyle(.primary)
            .accessibilityLabel(String(format: NSLocalizedString("pencilPushups.rep.accessibility", comment: "Rep counter accessibility"), currentRep, repTarget))
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(NSLocalizedString("pencilPushups.reps", comment: "Reps label"))
                    .font(.subheadline)
                Spacer()
                Picker(NSLocalizedString("pencilPushups.repPicker", comment: "Rep target picker label"), selection: $repTarget) {
                    Text("10").tag(10)
                    Text("15").tag(15)
                    Text("20").tag(20)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .accessibilityLabel(NSLocalizedString("pencilPushups.repPicker.accessibility", comment: "Rep target picker accessibility"))
            }

            HStack {
                Text(NSLocalizedString("pencilPushups.speedLabel", comment: "Speed label"))
                    .font(.subheadline)
                Spacer()
                Picker(NSLocalizedString("pencilPushups.speedPicker", comment: "Speed picker label"), selection: $speed) {
                    ForEach(PencilSpeed.allCases) { s in
                        Text(s.localizedName).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .accessibilityLabel(NSLocalizedString("pencilPushups.speedPicker.accessibility", comment: "Movement speed picker accessibility"))
            }

            Toggle(NSLocalizedString("pencilPushups.haptic", comment: "Haptic at near point toggle"), isOn: $hapticEnabled)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("pencilPushups.haptic.accessibility", comment: "Enable haptic feedback at near endpoint accessibility"))

            Toggle(NSLocalizedString("pencilPushups.audioCue", comment: "Audio cue toggle"), isOn: $audioCue)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("pencilPushups.audioCue.accessibility", comment: "Enable audio cue accessibility"))
        }
    }

    // MARK: - Session Timer

    private var sessionTimerLabel: some View {
        Text(String(format: NSLocalizedString("pencilPushups.session", comment: "Session timer label"), formatTime(elapsed)))
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel(String(format: NSLocalizedString("pencilPushups.sessionTime.accessibility", comment: "Session time accessibility"), Int(elapsed)))
    }

    // MARK: - Start / Stop

    private var startStopButton: some View {
        Button {
            if isRunning { stop() } else { start() }
        } label: {
            Text(isRunning ? NSLocalizedString("pencilPushups.stop", comment: "Stop button") : NSLocalizedString("pencilPushups.beginExercise", comment: "Begin exercise button"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? NSLocalizedString("pencilPushups.stop.accessibility", comment: "Stop pencil pushups exercise accessibility") : NSLocalizedString("pencilPushups.begin.accessibility", comment: "Begin pencil pushups exercise accessibility"))
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
