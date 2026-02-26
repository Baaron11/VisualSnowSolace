// QuickReliefView.swift
// Visual Snow Solace
//
// One-tap relief mode that simultaneously starts brown noise at 50% volume
// and launches a breathing exercise using the user's default preset from
// AppSettings. Shows inline controls for both audio and breathing.

import SwiftUI
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

struct QuickReliefView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(NoiseGenerator.self) private var noise
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var isActive = false
    @State private var currentPhaseIndex = 0
    @State private var phaseElapsed: TimeInterval = 0
    @State private var sessionTime: TimeInterval = 0
    @State private var circleScale: CGFloat = 1.0

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    private var phases: [BreathingPhase] {
        settings.defaultBreathingPreset.phases
    }

    private var currentPhase: BreathingPhase {
        phases[currentPhaseIndex]
    }

    private var phaseTimeRemaining: TimeInterval {
        max(0, currentPhase.duration - phaseElapsed)
    }

    var body: some View {
        @Bindable var noise = noise

        VStack(spacing: 24) {
            if isActive {
                activeView(noise: noise)
            } else {
                idleView
            }
        }
        .padding()
        .navigationTitle("Quick Relief")
        .onDisappear {
            stopRelief()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isActive else { return }
            tick()
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            Text("Quick Relief")
                .font(.title.bold())

            Text("Starts brown noise at 50% volume and a \(settings.defaultBreathingPreset.rawValue) breathing exercise together.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                startRelief()
            } label: {
                Text("Start Quick Relief")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Start quick relief session")

            DisclaimerFooter()
        }
    }

    // MARK: - Active View

    private func activeView(noise: NoiseGenerator) -> some View {
        let noiseBinding = Bindable(noise)

        return VStack(spacing: 24) {
            // Breathing display
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

            // Session timer
            Text("Session: \(formatTime(sessionTime))")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)

            // Volume slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Volume: \(Int(noise.volume * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Slider(value: noiseBinding.volume, in: 0...1)
                    .accessibilityLabel("Noise volume, \(Int(noise.volume * 100)) percent")
            }

            // Stop button
            Button {
                stopRelief()
            } label: {
                Text("Stop")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            .accessibilityLabel("Stop quick relief session")

            DisclaimerFooter()
        }
    }

    // MARK: - Timer Logic

    private func tick() {
        phaseElapsed += 0.1
        sessionTime += 0.1

        if phaseElapsed >= currentPhase.duration {
            advancePhase()
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

    // MARK: - Start / Stop

    private func startRelief() {
        // Start brown noise at 50% volume
        noise.noiseType = .brown
        noise.volume = 0.5
        noise.start()

        // Start breathing
        isActive = true
        currentPhaseIndex = 0
        phaseElapsed = 0
        sessionTime = 0
        animateToPhase(0)
    }

    private func stopRelief() {
        isActive = false
        noise.stop()
        currentPhaseIndex = 0
        phaseElapsed = 0
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.3)) {
                circleScale = 1.0
            }
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
