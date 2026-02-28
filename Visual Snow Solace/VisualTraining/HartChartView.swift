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

// MARK: - View

struct HartChartView: View {
    @State private var mode: HartChartMode = .standard
    @State private var standardGrid: [[Character]] = []
    @State private var cornerGrids: [[[Character]]] = []  // 4 grids of 4×4
    @State private var cornerColors: [[[Color]]] = []     // 4 grids of 4×4 colors
    @State private var sessionSeconds: Int = 0
    @State private var isRunning: Bool = false

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
}
