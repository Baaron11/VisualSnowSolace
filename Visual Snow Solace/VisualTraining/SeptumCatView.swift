// SeptumCatView.swift
// Visual Snow Solace
//
// Convergence Stereogram exercise. The user selects a stereogram image (cat
// or circles) and practices convergence and fusion by relaxing their focus
// until a third fused image appears. Includes a streak counter and a
// "Lost it — refocus" button.

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

struct ConvergenceStereogramView: View {
    @Environment(AppSettings.self) private var settings

    // Configuration
    @State private var durationMinutes: Double = 3
    @State private var hapticEnabled = true
    @State private var audioCue = false

    // Image selection
    @State private var showCat: Bool = true

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var streakTime: TimeInterval = 0
    @State private var bestStreak: TimeInterval = 0
    @State private var isStable = true // user hasn't tapped "lost it"
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false

    private var sessionDuration: TimeInterval {
        durationMinutes * 60
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                instructionsSection

                imagePicker

                stereogramImage

                if isRunning {
                    streakDisplay

                    lostItButton
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
        .navigationTitle(NSLocalizedString("convergenceStereogram.title", comment: "Navigation title for Convergence Stereogram exercise"))
        .onDisappear { stop() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
        .alert(NSLocalizedString("convergenceStereogram.breakAlert.title", comment: "Break alert title"), isPresented: $showBreakAlert) {
            Button(NSLocalizedString("convergenceStereogram.breakAlert.continue", comment: "Continue button in break alert")) {}
            Button(NSLocalizedString("convergenceStereogram.breakAlert.stop", comment: "Stop button in break alert"), role: .destructive) { stop() }
        } message: {
            Text(NSLocalizedString("convergenceStereogram.breakAlert.message", comment: "Break alert message suggesting rest"))
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("convergenceStereogram.instructions.title", comment: "Instructions section title"))
                .font(.headline)

            Text(NSLocalizedString("convergenceStereogram.instructions.body", comment: "Instructions for convergence stereogram exercise"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Image Picker

    private var imagePicker: some View {
        Picker(NSLocalizedString("convergenceStereogram.imagePicker", comment: "Image picker label"), selection: $showCat) {
            Text(NSLocalizedString("convergenceStereogram.image.cat", comment: "Cat image option")).tag(true)
            Text(NSLocalizedString("convergenceStereogram.image.circles", comment: "Circles image option")).tag(false)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Stereogram Image

    private var stereogramImage: some View {
        Group {
            if showCat {
                if UIImage(named: "cat") != nil {
                    Image("cat")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                } else {
                    imagePlaceholder(label: NSLocalizedString("convergenceStereogram.placeholder.cat", comment: "Placeholder label for cat stereogram"))
                }
            } else {
                if UIImage(named: "convergencecircles") != nil {
                    Image("convergencecircles")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                } else {
                    imagePlaceholder(label: NSLocalizedString("convergenceStereogram.placeholder.circles", comment: "Placeholder label for convergence circles stereogram"))
                }
            }
        }
    }

    private func imagePlaceholder(label: String) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 200)
            .overlay(
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            )
    }

    // MARK: - Streak Display

    private var streakDisplay: some View {
        VStack(spacing: 4) {
            Text(String(format: NSLocalizedString("convergenceStereogram.held", comment: "Current held time display"), formatSeconds(streakTime)))
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(isStable ? .green : .red)
                .contentTransition(.numericText())

            if bestStreak > 0 {
                Text(String(format: NSLocalizedString("convergenceStereogram.best", comment: "Best streak time display"), formatSeconds(bestStreak)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: NSLocalizedString("convergenceStereogram.streak.accessibility", comment: "Accessibility label for streak times"), Int(streakTime), Int(bestStreak)))
    }

    // MARK: - Lost It Button

    private var lostItButton: some View {
        Button {
            lostFocus()
        } label: {
            Label(NSLocalizedString("convergenceStereogram.lostIt", comment: "Lost it refocus button label"), systemImage: "eye.slash")
        }
        .buttonStyle(.bordered)
        .tint(.orange)
        .accessibilityLabel(NSLocalizedString("convergenceStereogram.lostIt.accessibility", comment: "Accessibility label for lost focus button"))
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(NSLocalizedString("convergenceStereogram.duration", comment: "Duration label"))
                    .font(.subheadline)
                Spacer()
                Picker(NSLocalizedString("convergenceStereogram.durationPicker", comment: "Duration picker label"), selection: $durationMinutes) {
                    Text(NSLocalizedString("convergenceStereogram.duration.1min", comment: "1 minute duration option")).tag(1.0)
                    Text(NSLocalizedString("convergenceStereogram.duration.3min", comment: "3 minute duration option")).tag(3.0)
                    Text(NSLocalizedString("convergenceStereogram.duration.5min", comment: "5 minute duration option")).tag(5.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .accessibilityLabel(NSLocalizedString("convergenceStereogram.durationPicker.accessibility", comment: "Accessibility label for session duration picker"))
            }

            Toggle(NSLocalizedString("convergenceStereogram.haptic", comment: "Haptic feedback toggle label"), isOn: $hapticEnabled)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("convergenceStereogram.haptic.accessibility", comment: "Accessibility label for haptic feedback toggle"))

            Toggle(NSLocalizedString("convergenceStereogram.audioCue", comment: "Audio cue toggle label"), isOn: $audioCue)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("convergenceStereogram.audioCue.accessibility", comment: "Accessibility label for audio cue toggle"))
        }
    }

    // MARK: - Session Timer

    private var sessionTimerLabel: some View {
        Text(String(format: NSLocalizedString("convergenceStereogram.session", comment: "Session timer label with time"), formatTime(elapsed)))
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel(String(format: NSLocalizedString("convergenceStereogram.sessionTime.accessibility", comment: "Accessibility label for session time in seconds"), Int(elapsed)))
    }

    // MARK: - Start / Stop

    private var startStopButton: some View {
        Button {
            if isRunning { stop() } else { start() }
        } label: {
            Text(isRunning ? NSLocalizedString("convergenceStereogram.stop", comment: "Stop button label") : NSLocalizedString("convergenceStereogram.beginExercise", comment: "Begin exercise button label"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? NSLocalizedString("convergenceStereogram.stop.accessibility", comment: "Accessibility label for stop convergence stereogram exercise") : NSLocalizedString("convergenceStereogram.begin.accessibility", comment: "Accessibility label for begin convergence stereogram exercise"))
    }

    private func start() {
        isRunning = true
        elapsed = 0
        streakTime = 0
        bestStreak = 0
        isStable = true
        breakAlertShown = false
    }

    private func stop() {
        isRunning = false
        elapsed = 0
        streakTime = 0
    }

    // MARK: - Logic

    private func tick() {
        elapsed += 0.1

        if elapsed >= sessionDuration {
            stop()
            return
        }

        if elapsed >= 300 && !breakAlertShown {
            breakAlertShown = true
            showBreakAlert = true
        }

        if isStable {
            streakTime += 0.1
            if streakTime > bestStreak {
                bestStreak = streakTime
            }
        }
    }

    private func lostFocus() {
        isStable = false
        streakTime = 0
        if hapticEnabled { triggerHaptic() }

        // Auto-recover after a brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard isRunning else { return }
            isStable = true
        }
    }

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return "\(s)s"
    }
}
