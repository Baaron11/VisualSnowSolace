// BrockStringView.swift
// Visual Snow Solace
//
// Brock String convergence exercise. Displays a reference image of the brock
// string setup and provides instructions, a pacing timer with haptic cues,
// and a configurable session timer.

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

struct BrockStringView: View {
    @Environment(AppSettings.self) private var settings

    // Configuration
    @State private var showExample: Bool = false
    @State private var durationMinutes: Double = 3
    @State private var hapticPacing = true
    @State private var audioCue = false
    @State private var pacingInterval: Double = 5 // seconds between focus shifts

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var focusedBead: Int = 0 // 0 = near, 1 = middle, 2 = far
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false
    @State private var timeSinceLastShift: TimeInterval = 0

    private var sessionDuration: TimeInterval {
        durationMinutes * 60
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                instructionsSection

                brockStringImage

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
        .navigationTitle(NSLocalizedString("brockString.title", comment: "Brock String navigation title"))
        .onDisappear { stop() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
        .alert(NSLocalizedString("brockString.breakAlert.title", comment: "Break alert title"), isPresented: $showBreakAlert) {
            Button(NSLocalizedString("brockString.breakAlert.continue", comment: "Continue button")) {}
            Button(NSLocalizedString("brockString.breakAlert.stop", comment: "Stop button"), role: .destructive) { stop() }
        } message: {
            Text(NSLocalizedString("brockString.breakAlert.message", comment: "Break alert message"))
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("brockString.instructions.title", comment: "Instructions heading"))
                .font(.headline)

            Text(NSLocalizedString("brockString.instructions.body", comment: "Brock string exercise instructions"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Image

    private var brockStringImage: some View {
        Group {
            Picker(NSLocalizedString("brockString.imagePicker", comment: "Image picker label"), selection: $showExample) {
                Text(NSLocalizedString("brockString.image.diagram", comment: "Diagram option")).tag(false)
                Text(NSLocalizedString("brockString.image.example", comment: "Example option")).tag(true)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(NSLocalizedString("brockString.imagePicker.accessibility", comment: "Brock String image type accessibility"))

            if showExample {
                if UIImage(named: "brockstringexample") != nil {
                    Image("brockstringexample")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .padding(.vertical, 8)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Text(NSLocalizedString("brockString.image.example.placeholder", comment: "Brock String example placeholder"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        )
                        .padding(.vertical, 8)
                }
            } else {
                if UIImage(named: "brockstring") != nil {
                    Image("brockstring")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .padding(.vertical, 8)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Text(NSLocalizedString("brockString.image.diagram.placeholder", comment: "Brock String diagram placeholder"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        )
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
            // Duration picker
            HStack {
                Text(NSLocalizedString("brockString.duration", comment: "Duration label"))
                    .font(.subheadline)
                Spacer()
                Picker(NSLocalizedString("brockString.durationPicker", comment: "Duration picker label"), selection: $durationMinutes) {
                    Text(NSLocalizedString("brockString.duration.1min", comment: "1 minute duration")).tag(1.0)
                    Text(NSLocalizedString("brockString.duration.3min", comment: "3 minute duration")).tag(3.0)
                    Text(NSLocalizedString("brockString.duration.5min", comment: "5 minute duration")).tag(5.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .accessibilityLabel(NSLocalizedString("brockString.durationPicker.accessibility", comment: "Session duration picker accessibility"))
            }

            // Pacing interval
            HStack {
                Text(NSLocalizedString("brockString.pacing", comment: "Pacing label"))
                    .font(.subheadline)
                Spacer()
                Picker(NSLocalizedString("brockString.pacingPicker", comment: "Pacing interval picker label"), selection: $pacingInterval) {
                    Text(NSLocalizedString("brockString.pacing.3s", comment: "3 second pacing")).tag(3.0)
                    Text(NSLocalizedString("brockString.pacing.5s", comment: "5 second pacing")).tag(5.0)
                    Text(NSLocalizedString("brockString.pacing.8s", comment: "8 second pacing")).tag(8.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .accessibilityLabel(NSLocalizedString("brockString.pacingPicker.accessibility", comment: "Haptic pacing interval accessibility"))
            }

            Toggle(NSLocalizedString("brockString.hapticPacing", comment: "Haptic pacing toggle"), isOn: $hapticPacing)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("brockString.hapticPacing.accessibility", comment: "Enable haptic pacing accessibility"))

            Toggle(NSLocalizedString("brockString.audioCue", comment: "Audio cue toggle"), isOn: $audioCue)
                .font(.subheadline)
                .accessibilityLabel(NSLocalizedString("brockString.audioCue.accessibility", comment: "Enable audio cue on focus shift accessibility"))
        }
    }

    // MARK: - Session Timer

    private var sessionTimerLabel: some View {
        Text(String(format: NSLocalizedString("brockString.session", comment: "Session timer label"), formatTime(elapsed)))
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel(String(format: NSLocalizedString("brockString.sessionTime.accessibility", comment: "Session time accessibility"), Int(elapsed)))
    }

    // MARK: - Start / Stop

    private var startStopButton: some View {
        Button {
            if isRunning { stop() } else { start() }
        } label: {
            Text(isRunning ? NSLocalizedString("brockString.stop", comment: "Stop button") : NSLocalizedString("brockString.beginExercise", comment: "Begin exercise button"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? NSLocalizedString("brockString.stop.accessibility", comment: "Stop brock string exercise accessibility") : NSLocalizedString("brockString.begin.accessibility", comment: "Begin brock string exercise accessibility"))
    }

    // MARK: - Logic

    private func start() {
        isRunning = true
        elapsed = 0
        timeSinceLastShift = 0
        focusedBead = 0
        breakAlertShown = false
    }

    private func stop() {
        isRunning = false
        elapsed = 0
        timeSinceLastShift = 0
    }

    private func tick() {
        elapsed += 0.1
        timeSinceLastShift += 0.1

        if elapsed >= sessionDuration {
            stop()
            return
        }

        if elapsed >= 300 && !breakAlertShown {
            breakAlertShown = true
            showBreakAlert = true
        }

        // Auto-advance bead focus based on pacing interval
        if timeSinceLastShift >= pacingInterval {
            timeSinceLastShift = 0
            focusedBead = (focusedBead + 1) % 3
            if hapticPacing { triggerHaptic() }
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
        return String(format: "%02d:%02d", mins, secs)
    }
}
