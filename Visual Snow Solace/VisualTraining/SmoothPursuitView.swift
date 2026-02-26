// SmoothPursuitView.swift
// Visual Snow Solace
//
// Smooth-pursuit eye-tracking exercise. A dot follows a continuous
// sinusoidal path — either horizontal or figure-8. The user can configure
// speed and path shape. Safety controls match SaccadesView: reduce-motion
// compliance, 5-minute break reminder, session duration setting.

import SwiftUI
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

// MARK: - Path Shape

enum PursuitPath: String, CaseIterable, Identifiable {
    case horizontal = "Horizontal"
    case figureEight = "Figure 8"

    var id: String { rawValue }
}

// MARK: - View

struct SmoothPursuitView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Configuration
    @State private var speed: Double = 1.0           // cycles per 10 seconds
    @State private var pathShape: PursuitPath = .horizontal
    @State private var durationMinutes: Double = 3

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false
    @State private var frameSize: CGSize = .zero

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    private var sessionDuration: TimeInterval {
        durationMinutes * 60
    }

    /// Current dot position computed from elapsed time.
    private var dotPosition: CGPoint {
        guard frameSize.width > 0, frameSize.height > 0 else {
            return CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        }

        let amplitude = reduceMotion ? 0.25 : 0.40
        let angularSpeed = speed * 2 * .pi / 10.0   // radians per second
        let t = elapsed * angularSpeed

        let cx = frameSize.width / 2
        let cy = frameSize.height / 2

        switch pathShape {
        case .horizontal:
            let x = cx + cos(t) * frameSize.width * amplitude
            return CGPoint(x: x, y: cy)
        case .figureEight:
            let x = cx + sin(t) * frameSize.width * amplitude
            let y = cy + sin(2 * t) * frameSize.height * amplitude * 0.5
            return CGPoint(x: x, y: y)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            if reduceMotion {
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
        .navigationTitle("Smooth Pursuit")
        .onDisappear { stop() }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
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
            Text("Reduce Motion is on — dot amplitude reduced.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: Reduce motion is enabled, dot amplitude is reduced.")
    }

    private var configurationControls: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Speed")
                    .font(.subheadline)
                Slider(value: $speed, in: 0.5...3.0, step: 0.25)
                    .accessibilityLabel("Speed, \(String(format: "%.1f", speed)) cycles")
                Text("\(String(format: "%.1f", speed))×")
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 40, alignment: .trailing)
            }

            Picker("Path", selection: $pathShape) {
                ForEach(PursuitPath.allCases) { path in
                    Text(path.rawValue).tag(path)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Path shape picker")

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
        .accessibilityLabel(isRunning ? "Stop smooth pursuit exercise" : "Start smooth pursuit exercise")
    }

    // MARK: - Logic

    private func start() {
        isRunning = true
        elapsed = 0
        breakAlertShown = false
    }

    private func stop() {
        isRunning = false
        elapsed = 0
    }

    private func tick() {
        elapsed += 0.016

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
        return String(format: "%d:%02d", mins, secs)
    }
}
