// PostItSaccadesView.swift
// Visual Snow Solace
//
// Post-It Saccades exercise for real-world saccadic training. Generates a
// randomized sequence of targets (letters, numbers, or shapes) that the
// user calls out while making deliberate saccades to physical sticky notes
// placed around their environment. Supports manual and auto-advance modes,
// optional audio readout via AVSpeechSynthesizer, and session tracking.

import SwiftUI
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
}

// MARK: - Speed Mode

enum PostItSpeedMode: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case auto = "Auto"

    var id: String { rawValue }
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
                    Text("Time: \(formatTime(elapsed))")
                        .font(.headline.monospacedDigit())
                        .accessibilityLabel("Session time: \(Int(elapsed)) seconds")

                    Spacer()

                    Text("Reps: \(reps)")
                        .font(.headline.monospacedDigit())
                        .accessibilityLabel("\(reps) repetitions completed")
                }
                .padding(.horizontal)
            }

            DisclaimerFooter()
        }
        .padding(.vertical)
        .navigationTitle("Post-It Saccades")
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
            Text("Place sticky notes with letters, numbers, or shapes around your environment — on walls, furniture, or a doorframe. Stand or sit in a fixed position. Call out each target and make a deliberate saccade to it, then return to a central fixation point. This exercise trains real-world saccadic accuracy across a large visual field.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } label: {
            Label("Instructions", systemImage: "info.circle")
                .font(.subheadline)
        }
        .padding(.horizontal)
        .accessibilityLabel("Instructions panel")
    }

    // MARK: - Configuration

    private var configSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Targets")
                    .font(.subheadline)
                Picker("Target Type", selection: $targetType) {
                    ForEach(SaccadeTargetType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Target type picker")
            }

            HStack {
                Text("Mode")
                    .font(.subheadline)
                Picker("Speed Mode", selection: $speedMode) {
                    ForEach(PostItSpeedMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Speed mode picker")
            }

            if speedMode == .auto {
                HStack {
                    Text("Interval")
                        .font(.subheadline)
                    Slider(value: $autoInterval, in: 1...5, step: 0.5)
                        .accessibilityLabel("Auto-advance interval, \(String(format: "%.1f", autoInterval)) seconds")
                    Text("\(String(format: "%.1f", autoInterval))s")
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 36, alignment: .trailing)
                }
            }

            HStack {
                Text("Count")
                    .font(.subheadline)
                Slider(value: Binding(
                    get: { Double(targetCount) },
                    set: { targetCount = Int($0) }
                ), in: 10...20, step: 1)
                    .accessibilityLabel("Target count, \(targetCount)")
                Text("\(targetCount)")
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 28, alignment: .trailing)
            }

            Toggle("Audio Readout", isOn: $audioEnabled)
                .font(.subheadline)
                .accessibilityLabel("Toggle audio readout of targets")
        }
        .padding(.horizontal)
    }

    // MARK: - Target Display

    private var currentTargetDisplay: some View {
        VStack(spacing: 8) {
            if targets.isEmpty {
                Text("Tap Generate Targets to start")
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
                    .accessibilityLabel("Current target: \(targets[currentIndex])")
            } else {
                Text("Sequence Complete!")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                    .accessibilityLabel("Target sequence complete")
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
                        .accessibilityLabel("Progress: \(currentIndex) of \(targets.count) targets")

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
                Button("Generate Targets") { generateAndStart() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityLabel("Generate target sequence and start")
            } else {
                HStack(spacing: 12) {
                    if speedMode == .manual {
                        Button {
                            advanceTarget()
                        } label: {
                            Text("Next")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(currentIndex >= targets.count)
                        .accessibilityLabel("Advance to next target")
                    }

                    Button {
                        stopSession()
                    } label: {
                        Text("Stop")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.red)
                    .accessibilityLabel("Stop exercise")
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
