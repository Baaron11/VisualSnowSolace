// LifesaverView.swift
// Visual Snow Solace
//
// Lifesaver (free-fusion) exercise. Provides instructions for using physical
// lifesaver cards, plus a configurable session timer with haptic feedback
// and break reminders.

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

struct LifesaverView: View {
    @Environment(AppSettings.self) private var settings

    // Configuration
    @State private var durationMinutes: Double = 3
    @State private var hapticEnabled = true

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false

    private var sessionDuration: TimeInterval {
        durationMinutes * 60
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "cart.fill")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("lifesaver.cardRequired.title", comment: "Title for lifesaver card required notice"))
                            .font(.subheadline.bold())
                        Text(NSLocalizedString("lifesaver.cardRequired.description", comment: "Description for how to find lifesaver cards"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 4)

                instructionCard

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
        .navigationTitle(NSLocalizedString("lifesaver.title", comment: "Navigation title for Lifesaver exercise"))
        .onDisappear { stop() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
        .alert(NSLocalizedString("lifesaver.breakAlert.title", comment: "Break alert title"), isPresented: $showBreakAlert) {
            Button(NSLocalizedString("lifesaver.breakAlert.continue", comment: "Continue button in break alert")) {}
            Button(NSLocalizedString("lifesaver.breakAlert.stop", comment: "Stop button in break alert"), role: .destructive) { stop() }
        } message: {
            Text(NSLocalizedString("lifesaver.breakAlert.message", comment: "Break alert message suggesting rest"))
        }
    }

    // MARK: - Instruction Card

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("lifesaver.instructions.title", comment: "Title for lifesaver instructions"))
                .font(.headline)

            Text(NSLocalizedString("lifesaver.instructions.body", comment: "Instructions for how to use lifesaver cards"))
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.07))
        )
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(NSLocalizedString("lifesaver.duration", comment: "Duration label"))
                    .font(.subheadline)
                Spacer()
                Picker(NSLocalizedString("lifesaver.durationPicker", comment: "Duration picker label"), selection: $durationMinutes) {
                    Text(NSLocalizedString("lifesaver.duration.1min", comment: "1 minute duration option")).tag(1.0)
                    Text(NSLocalizedString("lifesaver.duration.3min", comment: "3 minute duration option")).tag(3.0)
                    Text(NSLocalizedString("lifesaver.duration.5min", comment: "5 minute duration option")).tag(5.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .accessibilityLabel(NSLocalizedString("lifesaver.durationPicker.accessibility", comment: "Accessibility label for session duration picker"))
            }

            Toggle(NSLocalizedString("lifesaver.haptic", comment: "Haptic feedback toggle label"), isOn: $hapticEnabled)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("lifesaver.haptic.accessibility", comment: "Accessibility label for haptic feedback toggle"))
        }
    }

    // MARK: - Session Timer

    private var sessionTimerLabel: some View {
        Text(String(format: NSLocalizedString("lifesaver.session", comment: "Session timer label with time"), formatTime(elapsed)))
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel(String(format: NSLocalizedString("lifesaver.sessionTime.accessibility", comment: "Accessibility label for session time in seconds"), Int(elapsed)))
    }

    // MARK: - Start / Stop

    private var startStopButton: some View {
        Button {
            if isRunning { stop() } else { start() }
        } label: {
            Text(isRunning ? NSLocalizedString("lifesaver.stop", comment: "Stop button label") : NSLocalizedString("lifesaver.beginExercise", comment: "Begin exercise button label"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? NSLocalizedString("lifesaver.stop.accessibility", comment: "Accessibility label for stop lifesaver exercise") : NSLocalizedString("lifesaver.begin.accessibility", comment: "Accessibility label for begin lifesaver exercise"))
    }

    private func start() {
        isRunning = true
        elapsed = 0
        breakAlertShown = false
    }

    private func stop() {
        isRunning = false
        elapsed = 0
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
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
