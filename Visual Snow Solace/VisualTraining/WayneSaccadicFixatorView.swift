// WayneSaccadicFixatorView.swift
// Visual Snow Solace
//
// Wayne Saccadic Fixator simulation. A 5×5 grid of numbered circular
// buttons highlights one target at a time. The user taps the active target
// as quickly as possible. Tracks hits, misses, average reaction time, and
// personal best. Supports sequential or random target order, four difficulty
// levels, timed sessions (1–3 min), and reduce motion compliance.

import SwiftUI
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
        .navigationTitle("Wayne Saccadic Fixator")
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
            Text("The Wayne Saccadic Fixator trains saccadic speed, accuracy, and reaction time. Targets light up one at a time in a grid — tap the active target as quickly as possible. This app simulates the core training concept. For clinical WSF use, consult your vision therapist.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } label: {
            Label("Instructions", systemImage: "info.circle")
                .font(.subheadline)
        }
        .accessibilityLabel("Instructions panel")
    }

    // MARK: - Configuration

    private var configSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Difficulty")
                    .font(.subheadline)
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(WSFDifficulty.allCases) { d in
                        Text(d.rawValue).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Difficulty picker")
            }

            HStack {
                Text("Duration")
                    .font(.subheadline)
                Picker("Session Duration", selection: $sessionMinutes) {
                    Text("1 min").tag(1)
                    Text("2 min").tag(2)
                    Text("3 min").tag(3)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Session duration picker")
            }

            Toggle("Random Order", isOn: $randomOrder)
                .font(.subheadline)
                .accessibilityLabel("Toggle random target order")
        }
    }

    // MARK: - Score Bar

    private var scoreBar: some View {
        HStack(spacing: 16) {
            Label("\(hits)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("\(hits) hits")

            Label("\(misses)", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .accessibilityLabel("\(misses) misses")

            Spacer()

            Text("\(averageReactionMs) ms")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel("Average reaction time: \(averageReactionMs) milliseconds")
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
        .accessibilityLabel("Target \(index + 1), \(isActive ? "active" : "inactive")")
    }

    private func buttonColor(isActive: Bool, isFlashRed: Bool) -> Color {
        if isFlashRed { return .red.opacity(0.6) }
        if isActive { return .blue }
        return Color(.systemGray5)
    }

    // MARK: - Timer & Controls

    private var sessionTimerLabel: some View {
        Text("\(formatTime(elapsed)) / \(formatTime(sessionDuration))")
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel("Session time: \(Int(elapsed)) of \(Int(sessionDuration)) seconds")
    }

    private var startStopButton: some View {
        Button {
            if isRunning { stopSession() } else { startSession() }
        } label: {
            Text(isRunning ? "Stop" : "Start")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? "Stop exercise" : "Start exercise")
    }

    // MARK: - Summary Sheet

    private var summarySheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Session Complete")
                    .font(.title.bold())

                VStack(spacing: 12) {
                    summaryRow(label: "Hits", value: "\(hits)")
                    summaryRow(label: "Misses", value: "\(misses)")
                    summaryRow(label: "Avg Reaction", value: "\(averageReactionMs) ms")
                    summaryRow(label: "High Score", value: "\(highScore) hits")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))

                Spacer()

                Button("Done") {
                    showSummary = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Dismiss summary")
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
