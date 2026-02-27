// HartChartView.swift
// Visual Snow Solace
//
// Hart Chart exercise with three modes: Standard (distance/near letter grids),
// Four Corner (numbered dots in screen corners with dwell-time focus), and
// Four Corner Fixation/Saccades (randomized pulsing targets with center cross).
// Each mode includes session timer, haptic feedback, and configurable parameters.

import SwiftUI
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

// MARK: - Hart Chart Mode

enum HartChartMode: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case fourCorner = "Four Corner"
    case fixationSaccades = "Fixation/Saccades"

    var id: String { rawValue }
}

// MARK: - Standard Chart Display

enum ChartDisplay: String, CaseIterable, Identifiable {
    case distance = "Distance"
    case near = "Near"
    case both = "Both"

    var id: String { rawValue }
}

// MARK: - Dot Size

enum DotSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }

    var points: CGFloat {
        switch self {
        case .small:  return 24
        case .medium: return 36
        case .large:  return 48
        }
    }
}

// MARK: - Saccade Speed

enum SaccadeSpeed: String, CaseIterable, Identifiable {
    case slow = "Slow"
    case medium = "Medium"
    case fast = "Fast"

    var id: String { rawValue }

    var interval: TimeInterval {
        switch self {
        case .slow:   return 3.0
        case .medium: return 1.5
        case .fast:   return 0.75
        }
    }
}

// MARK: - View

struct HartChartView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    // Mode
    @State private var mode: HartChartMode = .standard

    // Standard mode state
    @State private var distanceLetters: [[Character]] = []
    @State private var nearLetters: [[Character]] = []
    @State private var chartDisplay: ChartDisplay = .distance
    @State private var currentRound = 1
    @State private var roundsComplete = false
    @State private var nearCardOffset: CGSize = .zero
    @State private var showInstructions = false
    @State private var checkmarkScale: CGFloat = 0

    // Four Corner mode state
    @State private var dotSizeChoice: DotSize = .medium
    @State private var showLabels = true
    @State private var randomizeOrder = false
    @State private var dwellTime: TimeInterval = 2
    @State private var autoAdvance = false
    @State private var cornerActiveIndex = 0
    @State private var cornerSequence: [Int] = [0, 1, 2, 3]
    @State private var cornerReps = 0
    @State private var cornerPulse = false

    // Fixation/Saccades mode state
    @State private var saccadeSpeed: SaccadeSpeed = .medium
    @State private var fixationActiveIndex: Int? = nil
    @State private var fixationSequence: [Int] = []
    @State private var fixationStep = 0
    @State private var fixationPulse = false
    @State private var fixationReps = 0
    @State private var showBreakAlert = false
    @State private var breakAlertShown = false

    // Shared state
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var timeSinceLastEvent: TimeInterval = 0

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    private let cornerColors: [Color] = [.red, .blue, .green, .yellow]

    var body: some View {
        VStack(spacing: 12) {
            Picker("Mode", selection: $mode) {
                ForEach(HartChartMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .disabled(isRunning)
            .accessibilityLabel("Hart Chart mode picker")

            switch mode {
            case .standard:
                standardModeContent
            case .fourCorner:
                fourCornerModeContent
            case .fixationSaccades:
                fixationSaccadesModeContent
            }

            DisclaimerFooter()
        }
        .padding(.vertical)
        .navigationTitle("Hart Chart")
        .onAppear { generateCharts() }
        .onDisappear { stopSession() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tickSession()
        }
        .alert("Take a Break", isPresented: $showBreakAlert) {
            Button("Continue") {}
            Button("Stop", role: .destructive) { stopSession() }
        } message: {
            Text("You have been exercising for 5 minutes. Consider resting your eyes.")
        }
    }

    // MARK: - Standard Mode

    private var standardModeContent: some View {
        VStack(spacing: 12) {
            instructionsPanel(
                text: "Place the large distance chart on a wall 3m away. Hold the near chart at 40cm. Read the first letter on the distance chart aloud, then shift focus to the first letter on the near chart. Continue alternating until all letters are complete. Do 5 rounds, 3 times per day."
            )

            Picker("Display", selection: $chartDisplay) {
                ForEach(ChartDisplay.allCases) { d in
                    Text(d.rawValue).tag(d)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 240)
            .disabled(isRunning)
            .accessibilityLabel("Chart display picker")

            ZStack {
                if chartDisplay == .distance || chartDisplay == .both {
                    chartGrid(letters: distanceLetters, fontSize: 18)
                        .accessibilityLabel("Distance Hart Chart")
                }

                if chartDisplay == .near || chartDisplay == .both {
                    nearChartCard
                }
            }
            .frame(maxWidth: .infinity, minHeight: 300)

            HStack(spacing: 16) {
                Text("Round \(currentRound) / 5")
                    .font(.headline.monospacedDigit())
                    .accessibilityLabel("Round \(currentRound) of 5")

                if roundsComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                        .scaleEffect(checkmarkScale)
                        .accessibilityLabel("All rounds complete")
                } else {
                    Button("Next Round") { advanceRound() }
                        .buttonStyle(.bordered)
                        .disabled(!isRunning)
                        .accessibilityLabel("Advance to next round")
                }
            }

            if isRunning {
                sessionTimerLabel
            }

            HStack(spacing: 12) {
                startStopButton

                Button("Shuffle") { generateCharts() }
                    .buttonStyle(.bordered)
                    .disabled(isRunning)
                    .accessibilityLabel("Shuffle chart letters")
            }
        }
        .padding(.horizontal)
    }

    private var nearChartCard: some View {
        chartGrid(letters: nearLetters, fontSize: 12)
            .frame(width: 280)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
            .shadow(radius: 4)
            .offset(nearCardOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in nearCardOffset = value.translation }
                    .onEnded { _ in }
            )
            .accessibilityLabel("Near Hart Chart, draggable")
    }

    private func chartGrid(letters: [[Character]], fontSize: CGFloat) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 10),
            spacing: 4
        ) {
            ForEach(0..<letters.count, id: \.self) { row in
                ForEach(0..<letters[row].count, id: \.self) { col in
                    Text(String(letters[row][col]))
                        .font(.system(size: fontSize, design: .monospaced))
                        .frame(minWidth: fontSize + 4, minHeight: fontSize + 4)
                }
            }
        }
    }

    // MARK: - Four Corner Mode

    private var fourCornerModeContent: some View {
        VStack(spacing: 12) {
            instructionsPanel(
                text: "Look directly at each numbered dot in sequence without moving your head. Hold focus on each dot for the set dwell time before shifting to the next."
            )

            fourCornerConfig
                .disabled(isRunning)

            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)

                    if isRunning {
                        fourCornerDots(in: geo.size)
                    } else {
                        Text("Tap Start to begin")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .padding(.horizontal)

            HStack {
                Text("Reps: \(cornerReps)")
                    .font(.headline.monospacedDigit())
                    .accessibilityLabel("\(cornerReps) repetitions completed")

                Spacer()

                if isRunning {
                    sessionTimerLabel
                }
            }
            .padding(.horizontal)

            startStopButton
                .padding(.horizontal)
        }
    }

    private var fourCornerConfig: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Dot Size")
                    .font(.subheadline)
                Picker("Dot Size", selection: $dotSizeChoice) {
                    ForEach(DotSize.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Dot size picker")
            }

            HStack {
                Text("Dwell")
                    .font(.subheadline)
                Picker("Dwell Time", selection: $dwellTime) {
                    Text("1s").tag(1.0 as TimeInterval)
                    Text("2s").tag(2.0 as TimeInterval)
                    Text("3s").tag(3.0 as TimeInterval)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Dwell time picker")
            }

            HStack {
                Toggle("Labels", isOn: $showLabels)
                    .accessibilityLabel("Show dot labels")
                Toggle("Random Order", isOn: $randomizeOrder)
                    .accessibilityLabel("Randomize dot order")
            }
            .font(.subheadline)

            Toggle("Auto-Advance", isOn: $autoAdvance)
                .font(.subheadline)
                .accessibilityLabel("Auto-advance to next dot")
        }
        .padding(.horizontal)
    }

    private func fourCornerDots(in size: CGSize) -> some View {
        let positions: [Alignment] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]
        let inset: CGFloat = dotSizeChoice.points

        return ZStack {
            ForEach(0..<4, id: \.self) { i in
                let seqIndex = cornerSequence[i]
                let isActive = cornerActiveIndex == i

                Circle()
                    .fill(cornerColors[seqIndex])
                    .frame(width: dotSizeChoice.points, height: dotSizeChoice.points)
                    .overlay {
                        if showLabels {
                            Text("\(seqIndex + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .overlay {
                        if isActive && autoAdvance {
                            Circle()
                                .stroke(cornerColors[seqIndex], lineWidth: 3)
                                .scaleEffect(cornerPulse ? 1.5 : 1.0)
                                .opacity(cornerPulse ? 0.3 : 0.8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: positions[i])
                    .padding(inset / 2)
                    .accessibilityLabel("Corner dot \(seqIndex + 1), \(isActive ? "active" : "inactive")")
            }
        }
        .onChange(of: cornerActiveIndex) { _, _ in
            if autoAdvance {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    cornerPulse = true
                }
            }
        }
    }

    // MARK: - Fixation/Saccades Mode

    private var fixationSaccadesModeContent: some View {
        VStack(spacing: 12) {
            instructionsPanel(
                text: "Fix your gaze on the center cross between each target. When a dot pulses, make a quick eye movement to it, then return to center."
            )

            if reduceMotion && saccadeSpeed != .slow {
                reduceMotionWarning
            }

            HStack {
                Text("Speed")
                    .font(.subheadline)
                Picker("Speed", selection: $saccadeSpeed) {
                    ForEach(SaccadeSpeed.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isRunning)
                .accessibilityLabel("Saccade speed picker")
            }
            .padding(.horizontal)

            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)

                    // Center fixation cross
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundStyle(.primary)
                        .accessibilityLabel("Center fixation cross")

                    if isRunning {
                        fixationDots(in: geo.size)
                    } else {
                        Text("Tap Start to begin")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .padding(.horizontal)

            HStack {
                Text("Reps: \(fixationReps)")
                    .font(.headline.monospacedDigit())
                    .accessibilityLabel("\(fixationReps) saccade repetitions")

                Spacer()

                if isRunning {
                    sessionTimerLabel
                }
            }
            .padding(.horizontal)

            startStopButton
                .padding(.horizontal)
        }
    }

    private func fixationDots(in size: CGSize) -> some View {
        let positions: [Alignment] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]
        let dotSize: CGFloat = DotSize.medium.points

        return ZStack {
            ForEach(0..<4, id: \.self) { i in
                let isActive = fixationActiveIndex == i

                Circle()
                    .fill(cornerColors[i])
                    .frame(
                        width: isActive ? dotSize * 1.4 : dotSize,
                        height: isActive ? dotSize * 1.4 : dotSize
                    )
                    .overlay {
                        if isActive {
                            Circle()
                                .stroke(cornerColors[i], lineWidth: 3)
                                .scaleEffect(fixationPulse ? 1.6 : 1.0)
                                .opacity(fixationPulse ? 0.2 : 0.7)
                        }
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: isActive)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: positions[i])
                    .padding(dotSize / 2)
                    .accessibilityLabel("Corner dot \(i + 1), \(isActive ? "active target" : "inactive")")
            }
        }
    }

    // MARK: - Shared Subviews

    private func instructionsPanel(text: String) -> some View {
        DisclosureGroup(isExpanded: $showInstructions) {
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } label: {
            Label("Instructions", systemImage: "info.circle")
                .font(.subheadline)
        }
        .padding(.horizontal)
        .accessibilityLabel("Instructions panel")
    }

    private var reduceMotionWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("Reduce Motion is on — speed limited to Slow.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: Reduce motion is enabled, speed is limited to slow.")
    }

    private var sessionTimerLabel: some View {
        Text(formatTime(elapsed))
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

    private func generateCharts() {
        distanceLetters = generateLetterGrid()
        nearLetters = generateLetterGrid()
    }

    private func generateLetterGrid() -> [[Character]] {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return (0..<10).map { _ in
            (0..<10).map { _ in chars.randomElement() ?? "A" } // randomElement always non-nil for non-empty
        }
    }

    private func startSession() {
        isRunning = true
        elapsed = 0
        timeSinceLastEvent = 0
        breakAlertShown = false

        switch mode {
        case .standard:
            currentRound = 1
            roundsComplete = false
            checkmarkScale = 0
        case .fourCorner:
            cornerActiveIndex = 0
            cornerReps = 0
            cornerPulse = false
            if randomizeOrder {
                cornerSequence = [0, 1, 2, 3].shuffled()
            } else {
                cornerSequence = [0, 1, 2, 3]
            }
        case .fixationSaccades:
            fixationStep = 0
            fixationReps = 0
            fixationPulse = false
            fixationSequence = (0..<20).map { _ in Int.random(in: 0..<4) }
            fixationActiveIndex = fixationSequence.first
            startFixationPulse()
        }
    }

    private func stopSession() {
        isRunning = false
        elapsed = 0
        timeSinceLastEvent = 0
        cornerPulse = false
        fixationPulse = false
        fixationActiveIndex = nil
    }

    private func tickSession() {
        elapsed += 0.1
        timeSinceLastEvent += 0.1

        // Break reminder at 5 minutes
        if elapsed >= 300 && !breakAlertShown {
            breakAlertShown = true
            showBreakAlert = true
        }

        switch mode {
        case .standard:
            break // Standard mode is manually advanced
        case .fourCorner:
            if autoAdvance && timeSinceLastEvent >= dwellTime {
                advanceCorner()
            }
        case .fixationSaccades:
            let effectiveSpeed = reduceMotion ? SaccadeSpeed.slow.interval : saccadeSpeed.interval
            if timeSinceLastEvent >= effectiveSpeed {
                advanceFixation()
            }
        }
    }

    private func advanceRound() {
        if currentRound < 5 {
            currentRound += 1
            triggerHaptic()
        }
        if currentRound >= 5 {
            roundsComplete = true
            triggerHaptic()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                checkmarkScale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    checkmarkScale = 1.0
                }
            }
        }
    }

    private func advanceCorner() {
        timeSinceLastEvent = 0
        cornerActiveIndex = (cornerActiveIndex + 1) % 4
        if cornerActiveIndex == 0 {
            cornerReps += 1
            triggerHaptic()
            if randomizeOrder {
                cornerSequence = [0, 1, 2, 3].shuffled()
            }
        }
    }

    private func advanceFixation() {
        timeSinceLastEvent = 0
        fixationStep += 1
        fixationReps += 1
        triggerHaptic()

        if fixationStep < fixationSequence.count {
            fixationActiveIndex = fixationSequence[fixationStep]
            startFixationPulse()
        } else {
            // Generate more targets
            fixationSequence = (0..<20).map { _ in Int.random(in: 0..<4) }
            fixationStep = 0
            fixationActiveIndex = fixationSequence.first
            startFixationPulse()
        }
    }

    private func startFixationPulse() {
        fixationPulse = false
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            fixationPulse = true
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
