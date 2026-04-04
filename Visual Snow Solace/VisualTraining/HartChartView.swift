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
import Foundation
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

    var localizedName: String {
        switch self {
        case .standard:        return NSLocalizedString("hartChart.mode.standard", comment: "Standard Hart Chart mode")
        case .fourCornerBW:    return NSLocalizedString("hartChart.mode.fourCornerBW", comment: "4 Corner B&W mode")
        case .fourCornerColor: return NSLocalizedString("hartChart.mode.fourCornerColor", comment: "4 Corner Color mode")
        }
    }
}

// MARK: - View

struct HartChartView: View {
    @State private var mode: HartChartMode = .standard
    @State private var saccadeInstructionsExpanded: Bool = false
    @State private var standardGrid: [[Character]] = []
    @State private var cornerGrids: [[[Character]]] = []  // 4 grids of 4×4
    @State private var cornerColors: [[[Color]]] = []     // 4 grids of 4×4 colors
    @State private var sessionSeconds: Int = 0
    @State private var isRunning: Bool = false
    @State private var showInfoDrawer: Bool = false

    // Metronome
    @State private var metronomeBPM: Double = 60.0
    @State private var metronomeActive: Bool = false
    @State private var metronomePhase: Bool = false // flips each beat for visual pulse
    @State private var lastBeatTime: Date = Date()
    private let metronomeTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    private let chars: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789")
    private let colorPalette: [Color] = [.red, .orange, .green, .blue]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
            // Mode picker
            Picker(NSLocalizedString("hartChart.chartTypePicker", comment: "Chart type picker label"), selection: $mode) {
                ForEach(HartChartMode.allCases) { m in
                    Text(m.localizedName).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityLabel(NSLocalizedString("hartChart.chartType.accessibility", comment: "Accessibility label for chart type picker"))

            // Shuffle button – trailing-aligned
            HStack {
                Spacer()
                Button {
                    generateAll()
                } label: {
                    Label(NSLocalizedString("hartChart.shuffle", comment: "Shuffle button label"), systemImage: "shuffle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(NSLocalizedString("hartChart.shuffle.accessibility", comment: "Accessibility label for generate new chart"))
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
                        Text(NSLocalizedString("hartChart.saccades.title", comment: "Vision Wall Saccades section title"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: saccadeInstructionsExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
                .accessibilityLabel(saccadeInstructionsExpanded ? NSLocalizedString("hartChart.saccades.collapse.accessibility", comment: "Accessibility label for collapse instructions") : NSLocalizedString("hartChart.saccades.expand.accessibility", comment: "Accessibility label for expand instructions"))

                if saccadeInstructionsExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("hartChart.saccades.howTo", comment: "How to use Hart Chart for Wall Saccades title"))
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(NSLocalizedString("hartChart.saccades.placement", comment: "Placement instructions for Hart Chart"))
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text(NSLocalizedString("hartChart.saccades.sequential.title", comment: "Standard sequential saccades title"))
                            .font(.subheadline).fontWeight(.semibold)
                        Text(NSLocalizedString("hartChart.saccades.sequential.body", comment: "Standard sequential saccades instructions"))
                            .font(.body).foregroundStyle(.secondary)

                        Divider()

                        Text(NSLocalizedString("hartChart.saccades.alternating.title", comment: "Standard alternating saccades title"))
                            .font(.subheadline).fontWeight(.semibold)
                        Text(NSLocalizedString("hartChart.saccades.alternating.body", comment: "Standard alternating saccades instructions"))
                            .font(.body).foregroundStyle(.secondary)

                        Divider()

                        Text(NSLocalizedString("hartChart.saccades.colorModes.title", comment: "4 Corner Color calling modes title"))
                            .font(.subheadline).fontWeight(.semibold)
                        Text(NSLocalizedString("hartChart.saccades.colorModes.intro", comment: "4 Corner Color calling modes introduction"))
                            .font(.body).foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Label(NSLocalizedString("hartChart.saccades.colorModes.colorOnly", comment: "Color only calling mode description"), systemImage: "circle.fill")
                                .font(.body).foregroundStyle(.secondary)
                            Label(NSLocalizedString("hartChart.saccades.colorModes.letterOnly", comment: "Letter only calling mode description"), systemImage: "textformat")
                                .font(.body).foregroundStyle(.secondary)
                            Label(NSLocalizedString("hartChart.saccades.colorModes.alternating", comment: "Alternating calling mode description"), systemImage: "arrow.left.arrow.right")
                                .font(.body).foregroundStyle(.secondary)
                        }
                        .padding(.leading, 8)

                        Divider()

                        Text(NSLocalizedString("hartChart.saccades.tips.title", comment: "Tips section title"))
                            .font(.subheadline).fontWeight(.semibold)
                        Text(NSLocalizedString("hartChart.saccades.tips.body", comment: "Tips for saccade exercises"))
                            .font(.body).foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal)

            // Chart display area
            Group {
                switch mode {
                case .standard:
                    standardChartView
                case .fourCornerBW:
                    fourCornerBWView
                case .fourCornerColor:
                    fourCornerColorView
                }
            }

            // Metronome
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: metronomeActive ? "metronome.fill" : "metronome")
                        .foregroundStyle(metronomeActive ? .blue : .secondary)
                        .font(.title3)
                        .scaleEffect(metronomePhase && metronomeActive ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: metronomePhase)
                        .accessibilityLabel(metronomeActive ? NSLocalizedString("hartChart.metronome.active.accessibility", comment: "Accessibility label for metronome active") : NSLocalizedString("hartChart.metronome.inactive.accessibility", comment: "Accessibility label for metronome inactive"))

                    Text(String(format: NSLocalizedString("hartChart.metronome.bpm", comment: "Metronome BPM display"), Int(metronomeBPM)))
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 72, alignment: .leading)

                    Slider(value: $metronomeBPM, in: 20...120, step: 1)
                        .accessibilityLabel(NSLocalizedString("hartChart.metronome.speed.accessibility", comment: "Accessibility label for metronome speed slider"))

                    Button(metronomeActive ? NSLocalizedString("hartChart.metronome.stop", comment: "Stop metronome button") : NSLocalizedString("hartChart.metronome.start", comment: "Start metronome button")) {
                        metronomeActive.toggle()
                        if metronomeActive {
                            lastBeatTime = Date()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel(metronomeActive ? NSLocalizedString("hartChart.metronome.stop.accessibility", comment: "Accessibility label for stop metronome") : NSLocalizedString("hartChart.metronome.start.accessibility", comment: "Accessibility label for start metronome"))
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
                Text(isRunning ? NSLocalizedString("hartChart.stop", comment: "Stop session button") : NSLocalizedString("hartChart.start", comment: "Start session button"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(isRunning ? .red : .blue)
            .padding(.horizontal)
            .accessibilityLabel(isRunning ? NSLocalizedString("hartChart.stop.accessibility", comment: "Accessibility label for stop session") : NSLocalizedString("hartChart.start.accessibility", comment: "Accessibility label for start session"))

            DisclaimerFooter()
        }
        .padding(.vertical)
        } // ScrollView
        .navigationTitle(NSLocalizedString("hartChart.title", comment: "Navigation title for Hart Chart"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showInfoDrawer = true
                } label: {
                    Image(systemName: "info.circle")
                        .accessibilityLabel(NSLocalizedString("hartChart.info.accessibility", comment: "Accessibility label for exercise info button"))
                }
            }
        }
        .sheet(isPresented: $showInfoDrawer) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(infoTitle)
                        .font(.title2.bold())
                        .padding(.top, 8)

                    if mode != .fourCornerColor {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(NSLocalizedString("hartChart.info.warning", comment: "Warning to not move head during exercise"))
                                .font(.body.bold())
                        }
                        .padding(12)
                        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    } else {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(NSLocalizedString("hartChart.info.warning", comment: "Warning to not move head during exercise"))
                                .font(.body.bold())
                        }
                        .padding(12)
                        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }

                    Text(infoBody)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
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

    // MARK: - Info Drawer Content

    private var infoTitle: String {
        switch mode {
        case .standard: return NSLocalizedString("hartchart.info.standard.title", comment: "Standard Hart Chart info title")
        case .fourCornerBW: return NSLocalizedString("hartchart.info.fourcornerBW.title", comment: "4 Corner B&W info title")
        case .fourCornerColor: return NSLocalizedString("hartchart.info.fourcornerColor.title", comment: "4 Corner Color info title")
        }
    }

    private var infoBody: String {
        switch mode {
        case .standard:
            return NSLocalizedString("hartchart.info.standard.body", comment: "Standard Hart Chart exercise instructions")

        case .fourCornerBW:
            return NSLocalizedString("hartchart.info.fourcornerBW.body", comment: "4 Corner B&W exercise instructions")

        case .fourCornerColor:
            return NSLocalizedString("hartchart.info.fourcornerColor.body", comment: "4 Corner Color exercise instructions")
        }
    }
}
