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

// MARK: - Breathing Overlay Content

private struct BreathingOverlayContent: View {
    let phaseName: String
    let phaseTimeRemaining: TimeInterval
    let circleScale: CGFloat
    let reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            VStack(spacing: 8) {
                Text(phaseName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(formatTime(phaseTimeRemaining))
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
        } else {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.7), .cyan.opacity(0.4)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(circleScale)

                VStack(spacing: 4) {
                    Text(phaseName)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(formatTime(phaseTimeRemaining))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct QuickReliefView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(NoiseGenerator.self) private var noise
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @AppStorage("visualStatic.showVisualStatic") private var showVisualStatic = false
    @AppStorage("visualStatic.grainSpeed") private var grainSpeed = 1.0
    @AppStorage("visualStatic.grainContrast") private var grainContrast = 0.5
    @AppStorage("visualStatic.hueRotation") private var hueRotation = 0.0

    @State private var isActive = false
    @State private var visualStaticActiveOnStart = false
    @State private var currentPhaseIndex = 0
    @State private var phaseElapsed: TimeInterval = 0
    @State private var sessionTime: TimeInterval = 0
    @State private var circleScale: CGFloat = 1.0
    @State private var showVisualStaticFullscreen = false

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

        ScrollView {
            VStack(spacing: 24) {
                if isActive {
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
                        .accessibilityLabel(String(format: NSLocalizedString("breathing.phaseRemaining.accessibility", comment: "Phase remaining accessibility"), currentPhase.name, Int(phaseTimeRemaining)))
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
                        .accessibilityLabel(String(format: NSLocalizedString("breathing.phaseRemaining.accessibility", comment: "Phase remaining accessibility"), currentPhase.name, Int(phaseTimeRemaining)))
                    }

                    // Visual static during session
                    if visualStaticActiveOnStart {
                        VisualStaticView(
                            grainSpeed: $grainSpeed,
                            grainContrast: $grainContrast,
                            hueRotation: $hueRotation,
                            showFullscreen: $showVisualStaticFullscreen,
                            overlayContent: {
                                AnyView(
                                    BreathingOverlayContent(
                                        phaseName: currentPhase.name,
                                        phaseTimeRemaining: phaseTimeRemaining,
                                        circleScale: circleScale,
                                        reduceMotion: reduceMotion
                                    )
                                )
                            }
                        )

                        Button {
                            showVisualStaticFullscreen = true
                        } label: {
                            Label(NSLocalizedString("quickRelief.fullscreen", comment: "Fullscreen button label"), systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .accessibilityLabel(NSLocalizedString("quickRelief.fullscreen.accessibility", comment: "Fullscreen button accessibility"))
                    }

                    // Stop button
                    Button {
                        stopRelief()
                    } label: {
                        Text(NSLocalizedString("quickRelief.stop", comment: "Stop button"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                    .accessibilityLabel(NSLocalizedString("quickRelief.stop.accessibility", comment: "Stop button accessibility"))
                } else {
                    Spacer()

                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)

                    Text(NSLocalizedString("quickRelief.title", comment: "Quick Relief title"))
                        .font(.title.bold())

                    Text(String(format: NSLocalizedString("quickRelief.description", comment: "Quick Relief description"), settings.defaultBreathingPreset.localizedName))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Visual Static toggle
                    Toggle(NSLocalizedString("quickRelief.visualStatic", comment: "Visual Static toggle"), isOn: $showVisualStatic)
                        .accessibilityLabel(NSLocalizedString("quickRelief.visualStatic.accessibility", comment: "Visual Static toggle accessibility"))

                    if showVisualStatic {
                        VisualStaticView(
                            grainSpeed: $grainSpeed,
                            grainContrast: $grainContrast,
                            hueRotation: $hueRotation,
                            showFullscreen: $showVisualStaticFullscreen
                        )

                        Button {
                            showVisualStaticFullscreen = true
                        } label: {
                            Label(NSLocalizedString("quickRelief.fullscreen", comment: "Fullscreen button label"), systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .accessibilityLabel(NSLocalizedString("quickRelief.fullscreen.accessibility", comment: "Fullscreen button accessibility"))
                    }

                    Spacer()

                    Button {
                        startRelief()
                    } label: {
                        Text(NSLocalizedString("quickRelief.startQuickRelief", comment: "Start Quick Relief button"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityLabel(NSLocalizedString("quickRelief.start.accessibility", comment: "Start button accessibility"))
                }

                // Volume slider (always visible)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: NSLocalizedString("quickRelief.volume", comment: "Volume label"), Int(noise.volume * 100)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Slider(value: $noise.volume, in: 0...1)
                        .accessibilityLabel(String(format: NSLocalizedString("quickRelief.volume.accessibility", comment: "Volume slider accessibility"), Int(noise.volume * 100)))
                }

                // Session timer
                if isActive {
                    Text(String(format: NSLocalizedString("quickRelief.session", comment: "Session timer"), formatTime(sessionTime)))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                DisclaimerFooter()
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("quickRelief.title", comment: "Quick Relief navigation title"))
        .onDisappear {
            stopRelief()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isActive else { return }
            tick()
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

        // Enable visual static if toggle is on
        visualStaticActiveOnStart = showVisualStatic

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
        return String(format: "%02d:%02d", mins, secs)
    }
}
