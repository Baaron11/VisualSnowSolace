// BreathingView.swift
// Visual Snow Solace
//
// Guided breathing exercise with three presets: Box (4-4-4-4), 4-7-8, and
// Paced (5-5). Shows an animated expanding/contracting circle during each
// phase. Respects accessibilityReduceMotion by replacing the circle with a
// text-only countdown. Triggers haptic feedback on each phase transition.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BreathingView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var selectedPreset: BreathingPreset = .box
    @State private var isRunning = false
    @State private var currentPhaseIndex = 0
    @State private var phaseElapsed: TimeInterval = 0
    @State private var sessionTime: TimeInterval = 0
    @State private var circleScale: CGFloat = 1.0

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    private var phases: [BreathingPhase] {
        selectedPreset.phases
    }

    private var currentPhase: BreathingPhase {
        phases[currentPhaseIndex]
    }

    private var phaseTimeRemaining: TimeInterval {
        max(0, currentPhase.duration - phaseElapsed)
    }

    var body: some View {
        VStack(spacing: 24) {
            presetPicker

            Spacer()

            if isRunning {
                breathingDisplay
            } else {
                idlePrompt
            }

            Spacer()

            if isRunning {
                sessionTimerLabel
            }

            startStopButton

            DisclaimerFooter()
        }
        .padding()
        .navigationTitle("Breathing")
        .onAppear {
            selectedPreset = settings.defaultBreathingPreset
        }
        .onDisappear {
            stopBreathing()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
    }

    // MARK: - Subviews

    private var presetPicker: some View {
        Picker("Preset", selection: $selectedPreset) {
            ForEach(BreathingPreset.allCases) { preset in
                Text(preset.rawValue).tag(preset)
            }
        }
        .pickerStyle(.segmented)
        .disabled(isRunning)
        .accessibilityLabel("Breathing preset picker")
    }

    @ViewBuilder
    private var breathingDisplay: some View {
        if reduceMotion {
            VStack(spacing: 8) {
                Text(currentPhase.name)
                    .font(.largeTitle.bold())
                    .contentTransition(.numericText())
                Text(formatTime(phaseTimeRemaining))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .contentTransition(.numericText())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(currentPhase.name), \(Int(phaseTimeRemaining)) seconds remaining")
        } else {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.7), .cyan.opacity(0.4)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(circleScale)

                VStack(spacing: 4) {
                    Text(currentPhase.name)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(formatTime(phaseTimeRemaining))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(currentPhase.name), \(Int(phaseTimeRemaining)) seconds remaining")
        }
    }

    private var idlePrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: "wind")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Tap Start to begin")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var sessionTimerLabel: some View {
        Text("Session: \(formatTime(sessionTime))")
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel("Session time: \(Int(sessionTime)) seconds")
    }

    private var startStopButton: some View {
        Button {
            if isRunning {
                stopBreathing()
            } else {
                startBreathing()
            }
        } label: {
            Text(isRunning ? "Stop" : "Start")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? "Stop breathing exercise" : "Start breathing exercise")
    }

    // MARK: - Timer Logic

    private func tick() {
        phaseElapsed += 0.1
        sessionTime += 0.1

        if phaseElapsed >= currentPhase.duration {
            advancePhase()
        }
    }

    private func startBreathing() {
        isRunning = true
        currentPhaseIndex = 0
        phaseElapsed = 0
        sessionTime = 0
        animateToPhase(0)
    }

    private func stopBreathing() {
        isRunning = false
        currentPhaseIndex = 0
        phaseElapsed = 0
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.3)) {
                circleScale = 1.0
            }
        }
    }

    private func advancePhase() {
        currentPhaseIndex = (currentPhaseIndex + 1) % phases.count
        phaseElapsed = 0
        animateToPhase(currentPhaseIndex)
        triggerHaptic()
    }

    private func animateToPhase(_ index: Int) {
        guard !reduceMotion else { return }
        let phase = phases[index]
        withAnimation(.easeInOut(duration: phase.duration)) {
            circleScale = phase.targetScale
        }
    }

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    // MARK: - Formatting

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
