// HandheldPencilSaccadesView.swift
// Visual Snow Solace
//
// Handheld Pencil Saccades exercise. Displays a Canvas-drawn background of
// random distractor letters/symbols at varying sizes and opacities, with a
// bold center target and a pencil-position indicator on the left. The user
// alternates focus between the physical pencil and the on-screen target.
// Configurable distractor density, auto-advance speed, and reduce motion.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Distractor Density

enum DistractorDensity: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    var count: Int {
        switch self {
        case .low:    return 40
        case .medium: return 80
        case .high:   return 150
        }
    }
}

// MARK: - Distractor Item

private struct DistractorItem: Identifiable {
    let id: Int
    let character: String
    let x: CGFloat      // 0–1 fraction
    let y: CGFloat      // 0–1 fraction
    let size: CGFloat    // font size
    let opacity: Double
    let rotation: Double
}

// MARK: - View

struct HandheldPencilSaccadesView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Configuration
    @State private var density: DistractorDensity = .medium
    @State private var autoAdvanceInterval: Double = 4
    @State private var showInstructions = false

    // Runtime
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var timeSinceLastChange: TimeInterval = 0
    @State private var currentTarget: String = "A"
    @State private var distractors: [DistractorItem] = []
    @State private var targetFlash = false

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    private let targetChars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    private let distractorChars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$%&*+?!~")

    var body: some View {
        VStack(spacing: 12) {
            instructionsPanel

            configSection
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
        .navigationTitle("Pencil Saccades")
        .onAppear { regenerateDistractors() }
        .onDisappear { stopSession() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
    }

    // MARK: - Instructions

    private var instructionsPanel: some View {
        DisclosureGroup(isExpanded: $showInstructions) {
            Text("Hold a pencil vertically at arm's length, slightly off-center. Place a background with visual detail behind it (a bookshelf, patterned wall, or the on-screen distractor grid). Perform saccades from the pencil tip to a fixed target (a letter on the wall or the on-screen target), then back. The background distractors challenge your brain to suppress irrelevant visual input while making accurate saccades.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } label: {
            Label("Instructions", systemImage: "info.circle")
                .font(.subheadline)
        }
        .accessibilityLabel("Instructions panel")
    }

    // MARK: - Configuration

    private var configSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Density")
                    .font(.subheadline)
                Picker("Distractor Density", selection: $density) {
                    ForEach(DistractorDensity.allCases) { d in
                        Text(d.rawValue).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Distractor density picker")
            }

            HStack {
                Text("Auto-Advance")
                    .font(.subheadline)
                Slider(value: $autoAdvanceInterval, in: 2...6, step: 0.5)
                    .accessibilityLabel("Auto-advance interval, \(String(format: "%.1f", autoAdvanceInterval)) seconds")
                Text("\(String(format: "%.1f", autoAdvanceInterval))s")
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Exercise Area

    private var exerciseArea: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)

                // Distractor layer
                ForEach(distractors) { item in
                    Text(item.character)
                        .font(.system(size: item.size, design: .monospaced))
                        .foregroundStyle(.primary.opacity(item.opacity))
                        .rotationEffect(.degrees(reduceMotion ? 0 : item.rotation))
                        .position(
                            x: item.x * size.width,
                            y: item.y * size.height
                        )
                        .accessibilityHidden(true)
                }

                // Pencil position indicator (left side)
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(.gray)
                        .frame(width: 4, height: size.height * 0.5)
                        .overlay(alignment: .top) {
                            Circle()
                                .fill(.gray)
                                .frame(width: 10, height: 10)
                                .offset(y: -5)
                        }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)
                .accessibilityLabel("Pencil position indicator on left side")

                // Center target
                Text(currentTarget)
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundStyle(.blue)
                    .opacity(targetFlash ? 0.4 : 1.0)
                    .accessibilityLabel("Saccade target: \(currentTarget)")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Timer & Controls

    private var sessionTimerLabel: some View {
        Text("Session: \(formatTime(elapsed))")
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel("Session time: \(Int(elapsed)) seconds")
    }

    private var startStopButton: some View {
        Button {
            if isRunning { stopSession() } else { startSession() }
        } label: {
            Text(isRunning ? "Stop" : "Start")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? "Stop exercise" : "Start exercise")
    }

    // MARK: - Logic

    private func startSession() {
        regenerateDistractors()
        randomizeTarget()
        isRunning = true
        elapsed = 0
        timeSinceLastChange = 0
    }

    private func stopSession() {
        isRunning = false
        elapsed = 0
        timeSinceLastChange = 0
        targetFlash = false
    }

    private func tick() {
        elapsed += 0.1
        timeSinceLastChange += 0.1

        if !reduceMotion && timeSinceLastChange >= autoAdvanceInterval {
            advanceTarget()
        }
    }

    private func advanceTarget() {
        timeSinceLastChange = 0
        triggerHaptic()

        // Brief flash animation
        if !reduceMotion {
            targetFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                targetFlash = false
            }
        }

        randomizeTarget()
    }

    private func randomizeTarget() {
        let newTarget = String(targetChars.randomElement() ?? "A") // randomElement on non-empty always succeeds
        currentTarget = newTarget
    }

    private func regenerateDistractors() {
        distractors = (0..<density.count).map { i in
            DistractorItem(
                id: i,
                character: String(distractorChars.randomElement() ?? "A"), // randomElement on non-empty always succeeds
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: 0.05...0.95),
                size: CGFloat.random(in: 8...22),
                opacity: Double.random(in: 0.15...0.55),
                rotation: Double.random(in: -30...30)
            )
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
        return String(format: "%d:%02d", mins, secs)
    }
}
