// WayneSaccadicFixatorView.swift
// Visual Snow Solace
//
// Wayne Saccadic Fixator simulation. A 5×5 grid of numbered circular
// buttons highlights one target at a time. The user taps the active target
// as quickly as possible. Tracks hits, misses, average reaction time, and
// personal best. Supports sequential or random target order, four difficulty
// levels, timed sessions (1–3 min), and reduce motion compliance.

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

// MARK: - Difficulty

enum WSFDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case challenge = "Challenge"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .easy:      return NSLocalizedString("wayne.difficulty.easy", comment: "Easy difficulty")
        case .medium:    return NSLocalizedString("wayne.difficulty.medium", comment: "Medium difficulty")
        case .hard:      return NSLocalizedString("wayne.difficulty.hard", comment: "Hard difficulty")
        case .challenge: return NSLocalizedString("wayne.difficulty.challenge", comment: "Challenge difficulty")
        }
    }

    var timeLimit: TimeInterval {
        switch self {
        case .easy:      return 3.0
        case .medium:    return 2.0
        case .hard:      return 1.0
        case .challenge: return 0.75
        }
    }
}

// MARK: - View

struct WayneSaccadicFixatorView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Configuration
    @State private var difficulty: WSFDifficulty = .medium
    @State private var randomOrder = false
    @State private var sessionMinutes: Int = 2

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var activeTarget: Int = 0    // 0–24
    @State private var hits = 0
    @State private var misses = 0
    @State private var reactionTimes: [TimeInterval] = []
    @State private var targetAppearTime: Date = .now
    @State private var timeSinceTargetShown: TimeInterval = 0
    @State private var flashRedTarget: Int? = nil
    @State private var pulseScale: CGFloat = 1.0

    // Session summary
    @State private var showSummary = false

    // Personal best
    @AppStorage("wayne.highScore") private var highScore: Int = 0

    @State private var showInstructions = false

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    private var sessionDuration: TimeInterval {
        Double(sessionMinutes) * 60
    }

    private var averageReactionMs: Int {
        guard !reactionTimes.isEmpty else { return 0 }
        let avg = reactionTimes.reduce(0, +) / Double(reactionTimes.count)
        return Int(avg * 1000)
    }

    var body: some View {
        VStack(spacing: 12) {
            instructionsPanel

            configSection
                .disabled(isRunning)

            if isRunning {
                scoreBar
            }

            gridArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isRunning {
                sessionTimerLabel
            }

            startStopButton

            DisclaimerFooter()
        }
        .padding()
        .navigationTitle(NSLocalizedString("wayne.title", comment: "Wayne Saccadic Fixator navigation title"))
        .onDisappear { stopSession() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
        .sheet(isPresented: $showSummary) {
            summarySheet
        }
    }

    // MARK: - Instructions

    private var instructionsPanel: some View {
        DisclosureGroup(isExpanded: $showInstructions) {
            Text(NSLocalizedString("wayne.instructions.body", comment: "Wayne Saccadic Fixator exercise instructions"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } label: {
            Label(NSLocalizedString("wayne.instructions.label", comment: "Instructions label"), systemImage: "info.circle")
                .font(.subheadline)
        }
        .accessibilityLabel(NSLocalizedString("wayne.instructions.accessibility", comment: "Instructions panel accessibility label"))
    }

    // MARK: - Configuration

    private var configSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(NSLocalizedString("wayne.difficulty", comment: "Difficulty label"))
                    .font(.subheadline)
                Picker(NSLocalizedString("wayne.difficultyPicker", comment: "Difficulty picker"), selection: $difficulty) {
                    ForEach(WSFDifficulty.allCases) { d in
                        Text(d.localizedName).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(NSLocalizedString("wayne.difficultyPicker.accessibility", comment: "Difficulty picker accessibility label"))
            }

            HStack {
                Text(NSLocalizedString("wayne.duration", comment: "Duration label"))
                    .font(.subheadline)
                Picker(NSLocalizedString("wayne.durationPicker", comment: "Session duration picker"), selection: $sessionMinutes) {
                    Text(NSLocalizedString("wayne.duration.1min", comment: "1 minute duration")).tag(1)
                    Text(NSLocalizedString("wayne.duration.2min", comment: "2 minute duration")).tag(2)
                    Text(NSLocalizedString("wayne.duration.3min", comment: "3 minute duration")).tag(3)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(NSLocalizedString("wayne.durationPicker.accessibility", comment: "Session duration picker accessibility label"))
            }

            Toggle(NSLocalizedString("wayne.randomOrder", comment: "Random order toggle"), isOn: $randomOrder)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("wayne.randomOrder.accessibility", comment: "Toggle random target order accessibility label"))
        }
    }

    // MARK: - Score Bar

    private var scoreBar: some View {
        HStack(spacing: 16) {
            Label("\(hits)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel(String(format: NSLocalizedString("wayne.hits.accessibility", comment: "Hits count accessibility label"), hits))

            Label("\(misses)", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .accessibilityLabel(String(format: NSLocalizedString("wayne.misses.accessibility", comment: "Misses count accessibility label"), misses))

            Spacer()

            Text("\(averageReactionMs) ms")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel(String(format: NSLocalizedString("wayne.avgReaction.accessibility", comment: "Average reaction time accessibility label"), averageReactionMs))
        }
        .font(.subheadline)
    }

    // MARK: - Grid

    private var gridArea: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
            spacing: 8
        ) {
            ForEach(0..<25, id: \.self) { index in
                gridButton(for: index)
            }
        }
    }

    private func gridButton(for index: Int) -> some View {
        let isActive = index == activeTarget && isRunning
        let isFlashRed = flashRedTarget == index

        return Button {
            handleTap(index)
        } label: {
            ZStack {
                Circle()
                    .fill(buttonColor(isActive: isActive, isFlashRed: isFlashRed))
                    .aspectRatio(1, contentMode: .fit)

                Text("\(index + 1)")
                    .font(.system(.body, design: .monospaced).bold())
                    .foregroundStyle(isActive ? .white : .primary)
            }
        }
        .scaleEffect(isActive && !reduceMotion ? pulseScale : 1.0)
        .disabled(!isRunning)
        .accessibilityLabel(isActive ? String(format: NSLocalizedString("wayne.target.active.accessibility", comment: "Active target accessibility label"), index + 1) : String(format: NSLocalizedString("wayne.target.inactive.accessibility", comment: "Inactive target accessibility label"), index + 1))
    }

    private func buttonColor(isActive: Bool, isFlashRed: Bool) -> Color {
        if isFlashRed { return .red.opacity(0.6) }
        if isActive { return .blue }
        return Color(.systemGray5)
    }

    // MARK: - Timer & Controls

    private var sessionTimerLabel: some View {
        Text(String(format: NSLocalizedString("wayne.sessionTimer", comment: "Session timer label"), formatTime(elapsed), formatTime(sessionDuration)))
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel(String(format: NSLocalizedString("wayne.sessionTimer.accessibility", comment: "Session timer accessibility label"), Int(elapsed), Int(sessionDuration)))
    }

    private var startStopButton: some View {
        Button {
            if isRunning { stopSession() } else { startSession() }
        } label: {
            Text(isRunning ? NSLocalizedString("wayne.stop", comment: "Stop button") : NSLocalizedString("wayne.start", comment: "Start button"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? NSLocalizedString("wayne.stop.accessibility", comment: "Stop exercise accessibility label") : NSLocalizedString("wayne.start.accessibility", comment: "Start exercise accessibility label"))
    }

    // MARK: - Summary Sheet

    private var summarySheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text(NSLocalizedString("wayne.summary.title", comment: "Session complete title"))
                    .font(.title.bold())

                VStack(spacing: 12) {
                    summaryRow(label: NSLocalizedString("wayne.summary.hits", comment: "Hits label"), value: "\(hits)")
                    summaryRow(label: NSLocalizedString("wayne.summary.misses", comment: "Misses label"), value: "\(misses)")
                    summaryRow(label: NSLocalizedString("wayne.summary.avgReaction", comment: "Average reaction label"), value: String(format: NSLocalizedString("wayne.summary.ms", comment: "Milliseconds value format"), averageReactionMs))
                    summaryRow(label: NSLocalizedString("wayne.summary.highScore", comment: "High score label"), value: String(format: NSLocalizedString("wayne.summary.hitsValue", comment: "Hits value format"), highScore))
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))

                Spacer()

                Button(NSLocalizedString("wayne.summary.done", comment: "Done button")) {
                    showSummary = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel(NSLocalizedString("wayne.summary.done.accessibility", comment: "Dismiss summary accessibility label"))
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
        }
    }

    // MARK: - Logic

    private func startSession() {
        isRunning = true
        elapsed = 0
        hits = 0
        misses = 0
        reactionTimes = []
        timeSinceTargetShown = 0
        flashRedTarget = nil

        if randomOrder {
            activeTarget = Int.random(in: 0..<25)
        } else {
            activeTarget = 0
        }

        targetAppearTime = .now
        startPulse()
    }

    private func stopSession() {
        isRunning = false
        elapsed = 0
        timeSinceTargetShown = 0
        pulseScale = 1.0
    }

    private func endSession() {
        isRunning = false
        if hits > highScore {
            highScore = hits
        }
        showSummary = true
        pulseScale = 1.0
    }

    private func tick() {
        elapsed += 0.1
        timeSinceTargetShown += 0.1

        if elapsed >= sessionDuration {
            endSession()
            return
        }

        // Auto-advance on miss
        if timeSinceTargetShown >= difficulty.timeLimit {
            misses += 1
            advanceTarget()
        }
    }

    private func handleTap(_ index: Int) {
        guard isRunning else { return }

        if index == activeTarget {
            let reaction = Date.now.timeIntervalSince(targetAppearTime)
            reactionTimes.append(reaction)
            hits += 1
            triggerHaptic()
            advanceTarget()
        } else {
            flashRedTarget = index
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if flashRedTarget == index {
                    flashRedTarget = nil
                }
            }
        }
    }

    private func advanceTarget() {
        timeSinceTargetShown = 0
        targetAppearTime = .now

        if randomOrder {
            var next = Int.random(in: 0..<25)
            // Avoid same target twice in a row
            while next == activeTarget {
                next = Int.random(in: 0..<25)
            }
            activeTarget = next
        } else {
            activeTarget = (activeTarget + 1) % 25
        }

        startPulse()
    }

    private func startPulse() {
        pulseScale = 1.0
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.12
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
        return String(format: "%d:%02d", mins, secs)
    }
}
