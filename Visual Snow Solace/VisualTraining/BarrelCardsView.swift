// BarrelCardsView.swift
// Visual Snow Solace
//
// Barrel card convergence exercise. Provides instructions for working with
// physical barrel cards, plus a configurable session timer with haptic
// and audio cue options.

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

struct BarrelCardsView: View {
    @Environment(AppSettings.self) private var settings

    // Configuration
    @State private var durationMinutes: Double = 3
    @State private var hapticEnabled = true
    @State private var audioCue = false

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
                    Image(systemName: "printer.fill")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("barrelCards.printout.title", comment: "Printout required title"))
                            .font(.subheadline.bold())
                        Text(NSLocalizedString("barrelCards.printout.description", comment: "Printout required description"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 4)

                instructionsSection

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
        .navigationTitle(NSLocalizedString("barrelCards.title", comment: "Barrel Cards navigation title"))
        .onDisappear { stop() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
        .alert(NSLocalizedString("barrelCards.breakAlert.title", comment: "Break alert title"), isPresented: $showBreakAlert) {
            Button(NSLocalizedString("barrelCards.breakAlert.continue", comment: "Continue button")) {}
            Button(NSLocalizedString("barrelCards.breakAlert.stop", comment: "Stop button"), role: .destructive) { stop() }
        } message: {
            Text(NSLocalizedString("barrelCards.breakAlert.message", comment: "Break alert message"))
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("barrelCards.instructions.title", comment: "Instructions heading"))
                .font(.headline)

            Text(NSLocalizedString("barrelCards.instructions.body", comment: "Barrel cards exercise instructions"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(NSLocalizedString("barrelCards.duration", comment: "Duration label"))
                    .font(.subheadline)
                Spacer()
                Picker(NSLocalizedString("barrelCards.durationPicker", comment: "Duration picker label"), selection: $durationMinutes) {
                    Text(NSLocalizedString("barrelCards.duration.1min", comment: "1 minute duration")).tag(1.0)
                    Text(NSLocalizedString("barrelCards.duration.3min", comment: "3 minute duration")).tag(3.0)
                    Text(NSLocalizedString("barrelCards.duration.5min", comment: "5 minute duration")).tag(5.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .accessibilityLabel(NSLocalizedString("barrelCards.durationPicker.accessibility", comment: "Session duration picker accessibility"))
            }

            Toggle(NSLocalizedString("barrelCards.haptic", comment: "Haptic on transition toggle"), isOn: $hapticEnabled)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("barrelCards.haptic.accessibility", comment: "Enable haptic feedback on ring transition accessibility"))

            Toggle(NSLocalizedString("barrelCards.audioCue", comment: "Audio cue toggle"), isOn: $audioCue)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("barrelCards.audioCue.accessibility", comment: "Enable audio chime on ring transition accessibility"))
        }
    }

    // MARK: - Session Timer

    private var sessionTimerLabel: some View {
        Text(String(format: NSLocalizedString("barrelCards.session", comment: "Session timer label"), formatTime(elapsed)))
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel(String(format: NSLocalizedString("barrelCards.sessionTime.accessibility", comment: "Session time accessibility"), Int(elapsed)))
    }

    // MARK: - Start / Stop

    private var startStopButton: some View {
        Button {
            if isRunning { stop() } else { start() }
        } label: {
            Text(isRunning ? NSLocalizedString("barrelCards.stop", comment: "Stop button") : NSLocalizedString("barrelCards.beginExercise", comment: "Begin exercise button"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? NSLocalizedString("barrelCards.stop.accessibility", comment: "Stop barrel cards exercise accessibility") : NSLocalizedString("barrelCards.begin.accessibility", comment: "Begin barrel cards exercise accessibility"))
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

    // MARK: - Tick

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
