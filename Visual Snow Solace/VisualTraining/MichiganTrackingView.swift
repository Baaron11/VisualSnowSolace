// MichiganTrackingView.swift
// Visual Snow Solace
//
// Michigan Tracking exercise with two modes: Underline Mode (drag to trace
// through letters, circling targets A–Z in order) and Eye-Only Mode (tap
// each target letter directly). Features a seeded random paragraph of
// capital letters, timer, personal best tracking, and accuracy counter.

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
internal import Combine
#endif

// MARK: - Tracking Mode

enum TrackingMode: String, CaseIterable, Identifiable {
    case underline = "Underline"
    case eyeOnly = "Eye-Only"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .underline: return NSLocalizedString("michigan.mode.underline", comment: "Underline tracking mode")
        case .eyeOnly:   return NSLocalizedString("michigan.mode.eyeOnly", comment: "Eye-Only tracking mode")
        }
    }
}

// MARK: - Letter Cell

private struct LetterCell: Identifiable {
    let id: Int
    let character: Character
    let row: Int
    let col: Int
    var circled: Bool = false
}

// MARK: - View

struct MichiganTrackingView: View {
    @Environment(AppSettings.self) private var settings

    // Configuration
    @State private var trackingMode: TrackingMode = .underline

    // Paragraph state
    @State private var cells: [LetterCell] = []
    @State private var targetIndex = 0 // 0 = A, 25 = Z
    @State private var seed: UInt64 = 0

    // Runtime
    @State private var isRunning = false
    @State private var isComplete = false
    @State private var elapsed: TimeInterval = 0
    @State private var correctCount = 0
    @State private var missCount = 0

    // Underline mode
    @State private var dragPath: [CGPoint] = []
    @State private var cellFrames: [Int: CGRect] = [:]

    // Eye-Only mode
    @State private var flashRedId: Int? = nil

    // Best time
    @AppStorage("michigan.bestTime") private var bestTime: Double = 0

    @State private var showInstructions = false

    private let columns = 30
    private let rows = 8
    private let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    private var currentTarget: Character {
        guard targetIndex < 26 else { return "Z" }
        return alphabet[targetIndex]
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker(NSLocalizedString("michigan.modePicker", comment: "Mode picker label"), selection: $trackingMode) {
                ForEach(TrackingMode.allCases) { m in
                    Text(m.localizedName).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .disabled(isRunning)
            .accessibilityLabel(NSLocalizedString("michigan.modePicker.accessibility", comment: "Tracking mode picker accessibility"))

            instructionsPanel

            targetDisplay

            letterGrid
                .padding(.horizontal, 4)

            statsBar

            HStack(spacing: 12) {
                startStopButton

                Button(NSLocalizedString("michigan.newParagraph", comment: "New paragraph button")) {
                    generateParagraph()
                    resetSession()
                }
                .buttonStyle(.bordered)
                .disabled(isRunning)
                .accessibilityLabel(NSLocalizedString("michigan.newParagraph.accessibility", comment: "Generate new paragraph accessibility"))
            }
            .padding(.horizontal)

            DisclaimerFooter()
        }
        .padding(.vertical)
        .navigationTitle(NSLocalizedString("michigan.title", comment: "Michigan Tracking navigation title"))
        .onAppear { generateParagraph() }
        .onDisappear { isRunning = false }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning, !isComplete else { return }
            elapsed += 0.1
        }
    }

    // MARK: - Instructions

    private var instructionsPanel: some View {
        DisclosureGroup(isExpanded: $showInstructions) {
            Group {
                if trackingMode == .underline {
                    Text(NSLocalizedString("michigan.instructions.underline", comment: "Underline mode instructions"))
                } else {
                    Text(NSLocalizedString("michigan.instructions.eyeOnly", comment: "Eye-only mode instructions"))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        } label: {
            Label(NSLocalizedString("michigan.instructions.label", comment: "Instructions disclosure label"), systemImage: "info.circle")
                .font(.subheadline)
        }
        .padding(.horizontal)
        .accessibilityLabel(NSLocalizedString("michigan.instructions.accessibility", comment: "Instructions panel accessibility"))
    }

    // MARK: - Target Display

    private var targetDisplay: some View {
        HStack {
            Text(NSLocalizedString("michigan.find", comment: "Find label"))
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(String(currentTarget))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.blue)
                .accessibilityLabel(String(format: NSLocalizedString("michigan.target.accessibility", comment: "Current target letter accessibility"), String(currentTarget)))

            if trackingMode == .eyeOnly {
                Spacer()
                Text(NSLocalizedString("michigan.noHeadMovement", comment: "No head movement reminder"))
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15), in: Capsule())
                    .accessibilityLabel(NSLocalizedString("michigan.noHeadMovement.accessibility", comment: "No head movement accessibility"))
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Letter Grid

    private var letterGrid: some View {
        GeometryReader { geo in
            let cellWidth = geo.size.width / CGFloat(columns)
            let cellHeight = geo.size.height / CGFloat(rows)

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)

                // Letters
                ForEach(cells) { cell in
                    let x = CGFloat(cell.col) * cellWidth + cellWidth / 2
                    let y = CGFloat(cell.row) * cellHeight + cellHeight / 2

                    Text(String(cell.character))
                        .font(.system(size: min(cellWidth, cellHeight) * 0.7, design: .monospaced))
                        .foregroundStyle(cellColor(for: cell))
                        .position(x: x, y: y)
                        .background(
                            GeometryReader { cellGeo in
                                Color.clear.onAppear {
                                    cellFrames[cell.id] = CGRect(
                                        x: x - cellWidth / 2,
                                        y: y - cellHeight / 2,
                                        width: cellWidth,
                                        height: cellHeight
                                    )
                                }
                            }
                        )
                }

                // Circle overlays on found letters
                ForEach(cells.filter { $0.circled }) { cell in
                    let x = CGFloat(cell.col) * cellWidth + cellWidth / 2
                    let y = CGFloat(cell.row) * cellHeight + cellHeight / 2
                    let radius = min(cellWidth, cellHeight) * 0.5

                    Circle()
                        .stroke(.blue, lineWidth: 2)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(x: x, y: y)
                        .accessibilityHidden(true)
                }

                // Underline path overlay
                if trackingMode == .underline && !dragPath.isEmpty {
                    Path { path in
                        path.move(to: dragPath[0])
                        for point in dragPath.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(.blue.opacity(0.5), lineWidth: 2)
                    .accessibilityHidden(true)
                }

                // Tap / drag gesture overlay
                if trackingMode == .underline {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard isRunning, !isComplete else { return }
                                    if !isRunning { return }
                                    dragPath.append(value.location)
                                    checkDragHit(at: value.location)
                                }
                                .onEnded { _ in }
                        )
                } else {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    guard isRunning, !isComplete else { return }
                                    handleTap(at: value.location, cellWidth: cellWidth, cellHeight: cellHeight)
                                }
                        )
                }
            }
        }
        .frame(height: 220)
        .accessibilityLabel(NSLocalizedString("michigan.grid.accessibility", comment: "Letter tracking grid accessibility"))
    }

    private func cellColor(for cell: LetterCell) -> Color {
        if cell.circled { return .blue }
        if flashRedId == cell.id { return .red }
        return .primary
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 16) {
            if isRunning || isComplete {
                Text(formatTime(elapsed))
                    .font(.headline.monospacedDigit())
                    .accessibilityLabel(String(format: NSLocalizedString("michigan.elapsed.accessibility", comment: "Elapsed time accessibility"), Int(elapsed)))
            }

            if bestTime > 0 {
                Text(String(format: NSLocalizedString("michigan.best", comment: "Best time label"), formatTime(bestTime)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(String(format: NSLocalizedString("michigan.best.accessibility", comment: "Personal best accessibility"), Int(bestTime)))
            }

            Spacer()

            if trackingMode == .eyeOnly {
                Text(String(format: NSLocalizedString("michigan.score", comment: "Score display"), correctCount, missCount))
                    .font(.subheadline.monospacedDigit())
                    .accessibilityLabel(String(format: NSLocalizedString("michigan.score.accessibility", comment: "Score accessibility"), correctCount, missCount))
            }

            if isComplete {
                Text(NSLocalizedString("michigan.complete", comment: "Exercise complete label"))
                    .font(.headline)
                    .foregroundStyle(.green)
                    .accessibilityLabel(NSLocalizedString("michigan.complete.accessibility", comment: "Exercise complete accessibility"))
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Controls

    private var startStopButton: some View {
        Button {
            if isRunning { stopTracking() } else { startTracking() }
        } label: {
            Text(isRunning ? NSLocalizedString("michigan.stop", comment: "Stop button") : NSLocalizedString("michigan.start", comment: "Start button"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(isRunning ? .red : .blue)
        .accessibilityLabel(isRunning ? NSLocalizedString("michigan.stop.accessibility", comment: "Stop tracking exercise accessibility") : NSLocalizedString("michigan.start.accessibility", comment: "Start tracking exercise accessibility"))
    }

    // MARK: - Paragraph Generation

    private func generateParagraph() {
        seed = UInt64.random(in: 0..<UInt64.max)
        var rng = SeededGenerator(seed: seed)

        let allChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let totalCells = rows * columns

        // Ensure each letter A–Z appears at least once
        var letters = alphabet
        while letters.count < totalCells {
            letters.append(allChars.randomElement(using: &rng) ?? "A") // randomElement on non-empty String always succeeds
        }
        letters.shuffle(using: &rng)

        cells = letters.enumerated().map { index, char in
            LetterCell(
                id: index,
                character: char,
                row: index / columns,
                col: index % columns
            )
        }
    }

    // MARK: - Session Control

    private func startTracking() {
        resetSession()
        isRunning = true
    }

    private func stopTracking() {
        isRunning = false
    }

    private func resetSession() {
        isRunning = false
        isComplete = false
        elapsed = 0
        targetIndex = 0
        correctCount = 0
        missCount = 0
        dragPath = []
        flashRedId = nil
        for i in cells.indices {
            cells[i].circled = false
        }
    }

    private func completeSession() {
        isComplete = true
        isRunning = false
        triggerHaptic()
        if bestTime == 0 || elapsed < bestTime {
            bestTime = elapsed
        }
    }

    // MARK: - Hit Detection

    private func checkDragHit(at point: CGPoint) {
        guard targetIndex < 26 else { return }
        let target = currentTarget
        for i in cells.indices {
            guard cells[i].character == target,
                  !cells[i].circled,
                  let frame = cellFrames[cells[i].id],
                  frame.contains(point)
            else { continue }

            cells[i].circled = true
            correctCount += 1
            targetIndex += 1
            triggerHaptic()
            if targetIndex >= 26 { completeSession() }
            return
        }
    }

    private func handleTap(at point: CGPoint, cellWidth: CGFloat, cellHeight: CGFloat) {
        let col = Int(point.x / cellWidth)
        let row = Int(point.y / cellHeight)
        guard row >= 0, row < rows, col >= 0, col < columns else { return }

        let cellIndex = row * columns + col
        guard cellIndex < cells.count else { return }

        if cells[cellIndex].character == currentTarget {
            cells[cellIndex].circled = true
            correctCount += 1
            targetIndex += 1
            triggerHaptic()
            if targetIndex >= 26 { completeSession() }
        } else {
            missCount += 1
            flashRedId = cells[cellIndex].id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if flashRedId == cells[cellIndex].id {
                    flashRedId = nil
                }
            }
        }
    }

    // MARK: - Helpers

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Seeded Random Generator

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
