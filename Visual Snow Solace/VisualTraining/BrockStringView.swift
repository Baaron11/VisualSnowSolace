// BrockStringView.swift
// Visual Snow Solace
//
// Brock String convergence exercise. Displays a reference image of the brock
// string setup and provides instructions, a pacing timer with haptic cues,
// and a configurable session timer.

import SwiftUI
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

struct BrockStringView: View {
    @Environment(AppSettings.self) private var settings

    // Configuration
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
        .navigationTitle("Brock String")
        .onDisappear { stop() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
        .alert("Take a Break", isPresented: $showBreakAlert) {
            Button("Continue") {}
            Button("Stop", role: .destructive) { stop() }
        } message: {
            Text("You have been exercising for 5 minutes. Consider resting your eyes.")
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.headline)

            Text("Attach a string (about 10 feet) to a fixed point at eye level. Place beads at 1 ft, 5 ft, and 9 ft. Hold the far end to your nose. Focus on the nearest bead — you should see two strings forming a V. Move focus to the middle bead (X shape), then the far bead (V pointing away). If you see only one string at any point, blink and refocus.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Image

    private var brockStringImage: some View {
        Group {
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
                        Text("Brock String diagram")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    )
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
            // Duration picker
            HStack {
                Text("Duration")
                    .font(.subheadline)
                Spacer()
                Picker("Duration", selection: $durationMinutes) {
                    Text("1 min").tag(1.0)
                    Text("3 min").tag(3.0)
                    Text("5 min").tag(5.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .accessibilityLabel("Session duration picker")
            }

            // Pacing interval
            HStack {
                Text("Pacing")
                    .font(.subheadline)
                Spacer()
                Picker("Pacing interval", selection: $pacingInterval) {
                    Text("3s").tag(3.0)
                    Text("5s").tag(5.0)
                    Text("8s").tag(8.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .accessibilityLabel("Haptic pacing interval")
            }

            Toggle("Haptic Pacing", isOn: $hapticPacing)
                .font(.subheadline)
                .accessibilityLabel("Enable haptic pacing")

            Toggle("Audio Cue", isOn: $audioCue)
                .font(.subheadline)
                .accessibilityLabel("Enable audio cue on focus shift")
        }
    }

    // MARK: - Session Timer

    private var sessionTimerLabel: some View {
        Text("Session: \(formatTime(elapsed))")
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel("Session time: \(Int(elapsed)) seconds")
    }

    // MARK: - Start / Stop

    private var startStopButton: some View {
        Button {
            if isRunning { stop() } else { start() }
        } label: {
            Text(isRunning ? "Stop" : "Begin Exercise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? "Stop brock string exercise" : "Begin brock string exercise")
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
