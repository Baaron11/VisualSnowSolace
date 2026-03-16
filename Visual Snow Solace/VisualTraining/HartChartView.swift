// HartChartView.swift
// Visual Snow Solace
//
// Hart Chart exercise with three display modes:
// - Standard: a 10×10 randomised letter/digit grid for distance focus-shifting.
// - Four Corner B&W: four independent 4×4 grids placed in each screen corner.
// - Four Corner Color: same four-corner layout with per-cell color constraints.
//
// All grids enforce an adjacency constraint: no cell shares the same character
// (or color, for the color mode) as any horizontally or vertically adjacent cell.
// Includes a session timer, shuffle control, and disclaimer footer.

import SwiftUI
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

// MARK: - Hart Chart Mode

enum HartChartMode: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case fourCornerBW = "4 Corner B&W"
    case fourCornerColor = "4 Corner Color"

    var id: String { rawValue }
}

// MARK: - Color Calling Mode

enum ColorCallingMode: String, CaseIterable {
    case color = "Color"
    case letter = "Letter"
    case alternating = "Alternating"
}

// MARK: - View

struct HartChartView: View {
    @State private var mode: HartChartMode = .standard
    @State private var saccadeInstructionsExpanded: Bool = false
    @State private var colorCallingMode: ColorCallingMode = .color
    @State private var standardGrid: [[Character]] = []
    @State private var cornerGrids: [[[Character]]] = []  // 4 grids of 4×4
    @State private var cornerColors: [[[Color]]] = []     // 4 grids of 4×4 colors
    @State private var sessionSeconds: Int = 0
    @State private var isRunning: Bool = false

    // Metronome
    @State private var metronomeBPM: Double = 60.0
    @State private var metronomeActive: Bool = false
    @State private var metronomePhase: Bool = false // flips each beat for visual pulse
    @State private var lastBeatTime: Date = Date()
    private let metronomeTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    private let chars: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789")
    private let colorPalette: [Color] = [.red, .orange, .green, .blue]

    var body: some View {
        VStack(spacing: 12) {
            // Mode picker
            Picker("Chart type", selection: $mode) {
                ForEach(HartChartMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityLabel("Chart type")

            // Shuffle button – trailing-aligned
            HStack {
                Spacer()
                Button {
                    generateAll()
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Generate new chart")
            }
            .padding(.horizontal)

            // Vision Wall Saccades instructions
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        saccadeInstructionsExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("Vision Wall Saccades")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: saccadeInstructionsExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
                .accessibilityLabel(saccadeInstructionsExpanded ? "Collapse instructions" : "Expand instructions")

                if saccadeInstructionsExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to use the Hart Chart for Wall Saccades")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("Place this chart on a wall at distance (2–3 meters). Stand or sit comfortably with your head still. Make deliberate eye movements between targets — do not move your head.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text("Standard — Sequential (1→10)")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("Starting at 1, move your eyes to each number in order across the chart: 1, 2, 3… through 10. Call each number aloud as you land on it. Repeat for each row.")
                            .font(.body).foregroundStyle(.secondary)

                        Divider()

                        Text("Standard — Alternating (1–10, 2–9…)")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("Begin at 1 on the left, then jump to 10 on the right. Then 2, then 9. Then 3, then 8 — continuing inward until you meet in the center. This trains larger amplitude saccades and symmetrical eye movement. Call each number or letter aloud as you land on it.")
                            .font(.body).foregroundStyle(.secondary)

                        Divider()

                        Text("4 Corner Color — Three calling modes")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("Use the 4 Corner Color chart on the wall. As you saccade to each target, call out:")
                            .font(.body).foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("**Color only** — say the color of the letter (e.g. \"Red\", \"Blue\")", systemImage: "circle.fill")
                                .font(.body).foregroundStyle(.secondary)
                            Label("**Letter only** — say the letter itself (e.g. \"A\", \"7\")", systemImage: "textformat")
                                .font(.body).foregroundStyle(.secondary)
                            Label("**Alternating** — alternate between calling the color and the letter on each successive target (e.g. \"Red\", \"B\", \"Green\", \"4\"…)", systemImage: "arrow.left.arrow.right")
                                .font(.body).foregroundStyle(.secondary)
                        }
                        .padding(.leading, 8)

                        Divider()

                        Text("Tips")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("Keep your head still throughout. Use the metronome below to pace your saccades — one beat per target. Take a break if you feel eye strain. Stop immediately if you feel dizzy or unwell.")
                            .font(.body).foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal)

            // Chart display area
            switch mode {
            case .standard:
                standardChartView
            case .fourCornerBW:
                fourCornerBWView
            case .fourCornerColor:
                fourCornerColorView
            }

            Spacer()

            // Metronome
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: metronomeActive ? "metronome.fill" : "metronome")
                        .foregroundStyle(metronomeActive ? .blue : .secondary)
                        .font(.title3)
                        .scaleEffect(metronomePhase && metronomeActive ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: metronomePhase)
                        .accessibilityLabel(metronomeActive ? "Metronome active" : "Metronome inactive")

                    Text("\(Int(metronomeBPM)) BPM")
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 72, alignment: .leading)

                    Slider(value: $metronomeBPM, in: 20...120, step: 1)
                        .accessibilityLabel("Metronome speed")

                    Button(metronomeActive ? "Stop" : "Start") {
                        metronomeActive.toggle()
                        if metronomeActive {
                            lastBeatTime = Date()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel(metronomeActive ? "Stop metronome" : "Start metronome")
                }
            }
            .padding(.horizontal)

            // Session timer (mm:ss)
            Text(formatTime(sessionSeconds))
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)

            // Start / Stop button
            Button {
                if isRunning {
                    isRunning = false
                    sessionSeconds = 0
                } else {
                    isRunning = true
                }
            } label: {
                Text(isRunning ? "Stop" : "Start")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(isRunning ? .red : .blue)
            .padding(.horizontal)
            .accessibilityLabel(isRunning ? "Stop session" : "Start session")

            DisclaimerFooter()
        }
        .padding(.vertical)
        .navigationTitle("Hart Chart")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { generateAll() }
        .onChange(of: mode) { _, _ in generateAll() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            sessionSeconds += 1
        }
        .onReceive(metronomeTimer) { now in
            guard metronomeActive else { return }
            let interval = 60.0 / metronomeBPM
            if now.timeIntervalSince(lastBeatTime) >= interval {
                lastBeatTime = now
                metronomePhase.toggle()
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
            }
        }
        .onDisappear {
            metronomeActive = false
        }
    }

    // MARK: - Standard Mode (10×10)

    private var standardChartView: some View {
        ScrollView {
            if standardGrid.count >= 10 {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 10), spacing: 0) {
                    ForEach(0..<100, id: \.self) { index in
                        let row = index / 10
                        let col = index % 10
                        Text(String(standardGrid[row][col]))
                            .font(.system(.title2, design: .monospaced, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .accessibilityLabel(String(standardGrid[row][col]))
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }

    // MARK: - Four Corner B&W

    private var fourCornerBWView: some View {
        GeometryReader { _ in
            ZStack {
                cornerGridView(grid: cornerGrids.indices.contains(0) ? cornerGrids[0] : [], colors: nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                cornerGridView(grid: cornerGrids.indices.contains(1) ? cornerGrids[1] : [], colors: nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                cornerGridView(grid: cornerGrids.indices.contains(2) ? cornerGrids[2] : [], colors: nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                cornerGridView(grid: cornerGrids.indices.contains(3) ? cornerGrids[3] : [], colors: nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .frame(height: UIScreen.main.bounds.width)
        .padding(.horizontal)
    }

    // MARK: - Four Corner Color

    private var fourCornerColorView: some View {
        VStack(spacing: 8) {
            Picker("Call out", selection: $colorCallingMode) {
                ForEach(ColorCallingMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityLabel("Color calling mode")

            Text(callingModeHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

        GeometryReader { _ in
            ZStack {
                cornerGridView(grid: cornerGrids.indices.contains(0) ? cornerGrids[0] : [], colors: cornerColors.indices.contains(0) ? cornerColors[0] : nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                cornerGridView(grid: cornerGrids.indices.contains(1) ? cornerGrids[1] : [], colors: cornerColors.indices.contains(1) ? cornerColors[1] : nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                cornerGridView(grid: cornerGrids.indices.contains(2) ? cornerGrids[2] : [], colors: cornerColors.indices.contains(2) ? cornerColors[2] : nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                cornerGridView(grid: cornerGrids.indices.contains(3) ? cornerGrids[3] : [], colors: cornerColors.indices.contains(3) ? cornerColors[3] : nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .frame(height: UIScreen.main.bounds.width)
        .padding(.horizontal)
        }
    }

    // MARK: - Calling Mode Hint

    private var callingModeHint: String {
        switch colorCallingMode {
        case .color: return "Say the color of each letter as you look at it."
        case .letter: return "Say the letter or number as you look at it."
        case .alternating: return "Alternate — first target say the color, next say the letter, and so on."
        }
    }

    // MARK: - Corner Grid Subview

    private func cornerGridView(grid: [[Character]], colors: [[Color]]?) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { col in
                        let char = grid[row][col]
                        let color: Color = colors?[row][col] ?? .primary
                        Text(String(char))
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                            .foregroundStyle(color)
                            .frame(width: 28, height: 28)
                            .accessibilityLabel(String(char))
                    }
                }
            }
        }
        .padding(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Generation

    private func generateAll() {
        standardGrid = generateCharGrid(rows: 10, cols: 10)
        cornerGrids = (0..<4).map { _ in generateCharGrid(rows: 4, cols: 4) }
        cornerColors = (0..<4).map { _ in generateColorGrid(rows: 4, cols: 4) }
    }

    private func generateCharGrid(rows: Int, cols: Int) -> [[Character]] {
        var grid: [[Character]] = []
        for row in 0..<rows {
            var rowArr: [Character] = []
            for col in 0..<cols {
                var bestCandidate = chars[0]
                for _ in 0..<20 {
                    let candidate = chars.randomElement() ?? chars[0]
                    var conflict = false
                    if col > 0 && rowArr[col - 1] == candidate {
                        conflict = true
                    }
                    if row > 0 && grid[row - 1][col] == candidate {
                        conflict = true
                    }
                    bestCandidate = candidate
                    if !conflict {
                        break
                    }
                }
                rowArr.append(bestCandidate)
            }
            grid.append(rowArr)
        }
        return grid
    }

    private func generateColorGrid(rows: Int, cols: Int) -> [[Color]] {
        var grid: [[Color]] = []
        for row in 0..<rows {
            var rowArr: [Color] = []
            for col in 0..<cols {
                var bestCandidate = colorPalette[0]
                for _ in 0..<20 {
                    let candidate = colorPalette.randomElement() ?? colorPalette[0]
                    var conflict = false
                    if col > 0 && rowArr[col - 1] == candidate {
                        conflict = true
                    }
                    if row > 0 && grid[row - 1][col] == candidate {
                        conflict = true
                    }
                    bestCandidate = candidate
                    if !conflict {
                        break
                    }
                }
                rowArr.append(bestCandidate)
            }
            grid.append(rowArr)
        }
        return grid
    }

    // MARK: - Helpers

    private func formatTime(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
