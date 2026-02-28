// SeptumCatView.swift
// Visual Snow Solace
//
// Convergence Stereogram exercise. The user selects a stereogram image (cat
// or circles) and practices convergence and fusion by relaxing their focus
// until a third fused image appears. Includes a streak counter and a
// "Lost it — refocus" button.

import SwiftUI
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
        .navigationTitle("Convergence Stereogram")
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

            Text("Choose an image above. Hold it at arm's length and relax your focus until a third image appears in the center — this is the fused stereogram image. Try to bring it into clear focus and hold it. Stop immediately if you feel eye strain or discomfort.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Image Picker

    private var imagePicker: some View {
        Picker("Image", selection: $showCat) {
            Text("Cat").tag(true)
            Text("Circles").tag(false)
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
                    imagePlaceholder(label: "Cat stereogram")
                }
            } else {
                if UIImage(named: "convergencecircles") != nil {
                    Image("convergencecircles")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                } else {
                    imagePlaceholder(label: "Convergence circles stereogram")
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
            Text("Held: \(formatSeconds(streakTime))")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(isStable ? .green : .red)
                .contentTransition(.numericText())

            if bestStreak > 0 {
                Text("Best: \(formatSeconds(bestStreak))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak: \(Int(streakTime)) seconds. Best streak: \(Int(bestStreak)) seconds")
    }

    // MARK: - Lost It Button

    private var lostItButton: some View {
        Button {
            lostFocus()
        } label: {
            Label("Lost it — refocus", systemImage: "eye.slash")
        }
        .buttonStyle(.bordered)
        .tint(.orange)
        .accessibilityLabel("Lost focus, tap to reset streak and refocus")
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 12) {
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

            Toggle("Haptic Feedback", isOn: $hapticEnabled)
                .font(.subheadline)
                .accessibilityLabel("Enable haptic feedback")

            Toggle("Audio Cue", isOn: $audioCue)
                .font(.subheadline)
                .accessibilityLabel("Enable audio cue")
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
        .accessibilityLabel(isRunning ? "Stop convergence stereogram exercise" : "Begin convergence stereogram exercise")
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
