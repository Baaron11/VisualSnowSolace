// SaccadesView.swift
// Visual Snow Solace
//
// Saccadic eye-movement exercise. A dot jumps between random positions
// inside a bounded frame. The user can configure jump interval (speed),
// amplitude (small / medium / large), and session duration (1–10 min).
// Respects Reduce Motion by limiting amplitude to small and showing a
// warning. Fires a break-reminder alert at the 5-minute mark.

import SwiftUI
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

// MARK: - Amplitude

enum SaccadeAmplitude: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }

    /// Fraction of the containing frame used for the dot bounds.
    var boundsFraction: CGFloat {
        switch self {
        case .small:  return 0.3
        case .medium: return 0.6
        case .large:  return 0.9
        }
    }
}

// MARK: - View

struct SaccadesView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Configuration
    @State private var interval: Double = 1.0        // seconds between jumps
    @State private var amplitude: SaccadeAmplitude = .medium
    @State private var durationMinutes: Double = 3   // session length

    // Runtime
    @State private var isRunning = false
    @State private var dotPosition: CGPoint = .zero
    @State private var elapsed: TimeInterval = 0
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false
    @State private var timeSinceLastJump: TimeInterval = 0
    @State private var frameSize: CGSize = .zero

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    private var effectiveAmplitude: SaccadeAmplitude {
        reduceMotion ? .small : amplitude
    }

    private var sessionDuration: TimeInterval {
        durationMinutes * 60
    }

    var body: some View {
        VStack(spacing: 16) {
            if reduceMotion && amplitude != .small {
                reduceMotionWarning
            }

            configurationControls
                .disabled(isRunning)

            exerciseArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isRunning {
                sessionTimerLabel
            }

            startStopButton

            DisclaimerFooter()
        }
        .padding()
        .navigationTitle("Saccades")
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

    // MARK: - Subviews

    private var reduceMotionWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("Reduce Motion is on — amplitude limited to Small.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: Reduce motion is enabled, amplitude is limited to small.")
    }

    private var configurationControls: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Speed")
                    .font(.subheadline)
                Slider(value: $interval, in: 0.5...3.0, step: 0.25)
                    .accessibilityLabel("Jump interval, \(String(format: "%.1f", interval)) seconds")
                Text("\(String(format: "%.1f", interval))s")
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 40, alignment: .trailing)
            }

            Picker("Amplitude", selection: $amplitude) {
                ForEach(SaccadeAmplitude.allCases) { amp in
                    Text(amp.rawValue).tag(amp)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Amplitude picker")

            HStack {
                Text("Duration")
                    .font(.subheadline)
                Slider(value: $durationMinutes, in: 1...10, step: 1)
                    .accessibilityLabel("Session duration, \(Int(durationMinutes)) minutes")
                Text("\(Int(durationMinutes)) min")
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }

    private var exerciseArea: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)

                if isRunning {
                    Circle()
                        .fill(.blue)
                        .frame(width: 24, height: 24)
                        .position(dotPosition)
                        .accessibilityHidden(true)
                }

                if !isRunning {
                    Text("Tap Start to begin")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear { frameSize = size }
            .onChange(of: size) { _, newSize in frameSize = newSize }
        }
    }

    private var sessionTimerLabel: some View {
        Text("Session: \(formatTime(elapsed)) / \(formatTime(sessionDuration))")
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel("Session time: \(Int(elapsed)) of \(Int(sessionDuration)) seconds")
    }

    private var startStopButton: some View {
        Button {
            if isRunning { stop() } else { start() }
        } label: {
            Text(isRunning ? "Stop" : "Start")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? "Stop saccades exercise" : "Start saccades exercise")
    }

    // MARK: - Logic

    private func start() {
        isRunning = true
        elapsed = 0
        timeSinceLastJump = 0
        breakAlertShown = false
        jumpToRandom()
    }

    private func stop() {
        isRunning = false
        elapsed = 0
        timeSinceLastJump = 0
    }

    private func tick() {
        elapsed += 0.1
        timeSinceLastJump += 0.1

        if elapsed >= sessionDuration {
            stop()
            return
        }

        if elapsed >= 300 && !breakAlertShown {
            breakAlertShown = true
            showBreakAlert = true
        }

        if timeSinceLastJump >= interval {
            timeSinceLastJump = 0
            jumpToRandom()
        }
    }

    private func jumpToRandom() {
        let fraction = effectiveAmplitude.boundsFraction
        let boundsW = frameSize.width * fraction
        let boundsH = frameSize.height * fraction
        let offsetX = (frameSize.width - boundsW) / 2
        let offsetY = (frameSize.height - boundsH) / 2

        let x = CGFloat.random(in: offsetX...(offsetX + boundsW))
        let y = CGFloat.random(in: offsetY...(offsetY + boundsH))
        dotPosition = CGPoint(x: x, y: y)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
