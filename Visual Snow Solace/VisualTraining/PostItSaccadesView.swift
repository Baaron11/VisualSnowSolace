// PostItSaccadesView.swift
// Visual Snow Solace
//
// Post-It Saccades exercise for real-world saccadic training. Generates a
// randomized sequence of targets (letters, numbers, or shapes) that the
// user calls out while making deliberate saccades to physical sticky notes
// placed around their environment. Supports manual and auto-advance modes,
// optional audio readout via AVSpeechSynthesizer, and session tracking.

import SwiftUI
import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

// MARK: - Target Type

enum SaccadeTargetType: String, CaseIterable, Identifiable {
    case letters = "Letters"
    case numbers = "Numbers"
    case shapes = "Shapes"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .letters: return NSLocalizedString("postItSaccades.targetType.letters", comment: "Letters target type")
        case .numbers: return NSLocalizedString("postItSaccades.targetType.numbers", comment: "Numbers target type")
        case .shapes:  return NSLocalizedString("postItSaccades.targetType.shapes", comment: "Shapes target type")
        }
    }
}

// MARK: - Speed Mode

enum PostItSpeedMode: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case auto = "Auto"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .manual: return NSLocalizedString("postItSaccades.speedMode.manual", comment: "Manual speed mode")
        case .auto:   return NSLocalizedString("postItSaccades.speedMode.auto", comment: "Auto speed mode")
        }
    }
}

// MARK: - View

struct PostItSaccadesView: View {
    @Environment(AppSettings.self) private var settings

    // Configuration
    @State private var targetType: SaccadeTargetType = .letters
    @State private var speedMode: PostItSpeedMode = .manual
    @State private var autoInterval: Double = 3
    @State private var targetCount: Int = 10
    @State private var audioEnabled = false

    // Runtime
    @State private var targets: [String] = []
    @State private var currentIndex = 0
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var reps = 0
    @State private var timeSinceLastAdvance: TimeInterval = 0

    // Audio
    @State private var synthesizer = AVSpeechSynthesizer()

    @State private var showInstructions = false

    private let shapeSymbols = ["●", "■", "▲", "◆", "★", "♦", "♣", "♠", "♥", "⬟", "⬡", "◯"]

    var body: some View {
        VStack(spacing: 16) {
            instructionsPanel

            configSection
                .disabled(isRunning)

            Spacer()

            currentTargetDisplay

            progressBar

            Spacer()

            controlButtons

            if isRunning {
                HStack {
                    Text(String(format: NSLocalizedString("postItSaccades.time", comment: "Session time display"), formatTime(elapsed)))
                        .font(.headline.monospacedDigit())
                        .accessibilityLabel(String(format: NSLocalizedString("postItSaccades.time.accessibility", comment: "Session time accessibility"), Int(elapsed)))

                    Spacer()

                    Text(String(format: NSLocalizedString("postItSaccades.reps", comment: "Reps display"), reps))
                        .font(.headline.monospacedDigit())
                        .accessibilityLabel(String(format: NSLocalizedString("postItSaccades.reps.accessibility", comment: "Reps accessibility"), reps))
                }
                .padding(.horizontal)
            }

            DisclaimerFooter()
        }
        .padding(.vertical)
        .navigationTitle(NSLocalizedString("postItSaccades.title", comment: "Post-It Saccades navigation title"))
        .onDisappear { stopSession() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            elapsed += 0.1
            if speedMode == .auto {
                timeSinceLastAdvance += 0.1
                if timeSinceLastAdvance >= autoInterval {
                    advanceTarget()
                }
            }
        }
    }

    // MARK: - Instructions

    private var instructionsPanel: some View {
        DisclosureGroup(isExpanded: $showInstructions) {
            Text(NSLocalizedString("postItSaccades.instructions.body", comment: "Post-It Saccades instructions body"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } label: {
            Label(NSLocalizedString("postItSaccades.instructions.label", comment: "Instructions disclosure label"), systemImage: "info.circle")
                .font(.subheadline)
        }
        .padding(.horizontal)
        .accessibilityLabel(NSLocalizedString("postItSaccades.instructions.accessibility", comment: "Instructions panel accessibility"))
    }

    // MARK: - Configuration

    private var configSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text(NSLocalizedString("postItSaccades.targets", comment: "Targets label"))
                    .font(.subheadline)
                Picker(NSLocalizedString("postItSaccades.targetTypePicker", comment: "Target type picker label"), selection: $targetType) {
                    ForEach(SaccadeTargetType.allCases) { t in
                        Text(t.localizedName).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(NSLocalizedString("postItSaccades.targetTypePicker.accessibility", comment: "Target type picker accessibility"))
            }

            HStack {
                Text(NSLocalizedString("postItSaccades.mode", comment: "Mode label"))
                    .font(.subheadline)
                Picker(NSLocalizedString("postItSaccades.speedModePicker", comment: "Speed mode picker label"), selection: $speedMode) {
                    ForEach(PostItSpeedMode.allCases) { m in
                        Text(m.localizedName).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(NSLocalizedString("postItSaccades.speedModePicker.accessibility", comment: "Speed mode picker accessibility"))
            }

            if speedMode == .auto {
                HStack {
                    Text(NSLocalizedString("postItSaccades.interval", comment: "Interval label"))
                        .font(.subheadline)
                    Slider(value: $autoInterval, in: 1...5, step: 0.5)
                        .accessibilityLabel(String(format: NSLocalizedString("postItSaccades.interval.accessibility", comment: "Auto-advance interval accessibility"), String(format: "%.1f", autoInterval)))
                    Text("\(String(format: "%.1f", autoInterval))s")
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 36, alignment: .trailing)
                }
            }

            HStack {
                Text(NSLocalizedString("postItSaccades.count", comment: "Count label"))
                    .font(.subheadline)
                Slider(value: Binding(
                    get: { Double(targetCount) },
                    set: { targetCount = Int($0) }
                ), in: 10...20, step: 1)
                    .accessibilityLabel(String(format: NSLocalizedString("postItSaccades.count.accessibility", comment: "Target count accessibility"), targetCount))
                Text("\(targetCount)")
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 28, alignment: .trailing)
            }

            Toggle(NSLocalizedString("postItSaccades.audioReadout", comment: "Audio readout toggle"), isOn: $audioEnabled)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("postItSaccades.audioReadout.accessibility", comment: "Audio readout accessibility"))
        }
        .padding(.horizontal)
    }

    // MARK: - Target Display

    private var currentTargetDisplay: some View {
        VStack(spacing: 8) {
            if targets.isEmpty {
                Text(NSLocalizedString("postItSaccades.tapToStart", comment: "Tap to start prompt"))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else if currentIndex < targets.count {
                Text(targets[currentIndex])
                    .font(.system(size: 96, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(minWidth: 140, minHeight: 140)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                    .accessibilityLabel(String(format: NSLocalizedString("postItSaccades.currentTarget.accessibility", comment: "Current target accessibility"), targets[currentIndex]))
            } else {
                Text(NSLocalizedString("postItSaccades.sequenceComplete", comment: "Sequence complete label"))
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                    .accessibilityLabel(NSLocalizedString("postItSaccades.sequenceComplete.accessibility", comment: "Target sequence complete accessibility"))
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        Group {
            if !targets.isEmpty {
                VStack(spacing: 4) {
                    ProgressView(value: Double(currentIndex), total: Double(targets.count))
                        .tint(.blue)
                        .accessibilityLabel(String(format: NSLocalizedString("postItSaccades.progress.accessibility", comment: "Progress accessibility"), currentIndex, targets.count))

                    Text("\(currentIndex) / \(targets.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Controls

    private var controlButtons: some View {
        VStack(spacing: 10) {
            if !isRunning {
                Button(NSLocalizedString("postItSaccades.generateTargets", comment: "Generate targets button")) { generateAndStart() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityLabel(NSLocalizedString("postItSaccades.generateTargets.accessibility", comment: "Generate target sequence accessibility"))
            } else {
                HStack(spacing: 12) {
                    if speedMode == .manual {
                        Button {
                            advanceTarget()
                        } label: {
                            Text(NSLocalizedString("postItSaccades.next", comment: "Next button"))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(currentIndex >= targets.count)
                        .accessibilityLabel(NSLocalizedString("postItSaccades.next.accessibility", comment: "Advance to next target accessibility"))
                    }

                    Button {
                        stopSession()
                    } label: {
                        Text(NSLocalizedString("postItSaccades.stop", comment: "Stop button"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.red)
                    .accessibilityLabel(NSLocalizedString("postItSaccades.stop.accessibility", comment: "Stop exercise accessibility"))
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Logic

    private func generateAndStart() {
        targets = (0..<targetCount).map { _ in randomTarget() }
        currentIndex = 0
        elapsed = 0
        timeSinceLastAdvance = 0
        reps += 1
        isRunning = true
        speakCurrentTarget()
    }

    private func advanceTarget() {
        timeSinceLastAdvance = 0
        currentIndex += 1
        triggerHaptic()

        if currentIndex >= targets.count {
            stopSession()
        } else {
            speakCurrentTarget()
        }
    }

    private func stopSession() {
        isRunning = false
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func randomTarget() -> String {
        switch targetType {
        case .letters:
            return String("ABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement() ?? "A") // randomElement on non-empty always succeeds
        case .numbers:
            return "\(Int.random(in: 1...99))"
        case .shapes:
            return shapeSymbols.randomElement() ?? "●" // randomElement on non-empty always succeeds
        }
    }

    private func speakCurrentTarget() {
        guard audioEnabled, currentIndex < targets.count else { return }
        let utterance = AVSpeechUtterance(string: targets[currentIndex])
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
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
