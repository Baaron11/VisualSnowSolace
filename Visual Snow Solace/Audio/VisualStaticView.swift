// VisualStaticView.swift
// Visual Snow Solace
//
// Reusable SwiftUI view that renders procedural animated grain using
// TimelineView + Canvas. Provides sliders for speed, contrast, and hue
// rotation, plus a fullscreen presentation mode.

import SwiftUI

struct VisualStaticView: View {
    @Binding var grainSpeed: Double
    @Binding var grainContrast: Double
    @Binding var hueRotation: Double
    @Binding var showFullscreen: Bool

    var overlayContent: (() -> AnyView)? = nil

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(AppSettings.self) private var settings

    private var reduceMotion: Bool {
        settings.reduceMotionOverride || systemReduceMotion
    }

    var body: some View {
        VStack(spacing: 16) {
            grainCanvas
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if reduceMotion {
                Text("Motion reduced")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            sliders
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            fullscreenView
        }
    }

    // MARK: - Grain Canvas

    private var grainCanvas: some View {
        TimelineView(reduceMotion ? .animation(minimumInterval: nil, paused: true) : .animation(minimumInterval: 1.0 / (grainSpeed * 10))) { timeline in
            Canvas { context, size in
                let seed: UInt64
                if reduceMotion {
                    seed = 42
                } else {
                    seed = UInt64(timeline.date.timeIntervalSinceReferenceDate * 1000) & 0xFFFFFFFF
                }
                drawGrain(context: context, size: size, seed: seed)
            }
        }
        .accessibilityLabel("Animated visual static grain")
    }

    // MARK: - Sliders

    private var sliders: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speed: \(grainSpeed, specifier: "%.1f")x")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Slider(value: $grainSpeed, in: 0.1...3.0)
                    .accessibilityLabel("Grain speed, \(grainSpeed, specifier: "%.1f") x")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Grain Contrast: \(Int(grainContrast * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Slider(value: $grainContrast, in: 0.0...1.0)
                    .accessibilityLabel("Grain contrast, \(Int(grainContrast * 100)) percent")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Hue Rotation: \(Int(hueRotation))\u{00B0}")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Slider(value: $hueRotation, in: 0...360)
                    .accessibilityLabel("Hue rotation, \(Int(hueRotation)) degrees")
            }
        }
    }

    // MARK: - Fullscreen

    private var fullscreenView: some View {
        ZStack(alignment: .topTrailing) {
            TimelineView(reduceMotion ? .animation(minimumInterval: nil, paused: true) : .animation(minimumInterval: 1.0 / (grainSpeed * 10))) { timeline in
                Canvas { context, size in
                    let seed: UInt64
                    if reduceMotion {
                        seed = 42
                    } else {
                        seed = UInt64(timeline.date.timeIntervalSinceReferenceDate * 1000) & 0xFFFFFFFF
                    }
                    drawGrain(context: context, size: size, seed: seed)
                }
            }
            .ignoresSafeArea()
            .accessibilityLabel("Fullscreen visual static grain")
            .overlay(alignment: .center) {
                if let overlayContent {
                    overlayContent()
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(16)
                }
            }

            Button {
                showFullscreen = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            .padding()
            .accessibilityLabel("Dismiss fullscreen")
        }
    }

    // MARK: - Grain Drawing

    private func drawGrain(context: GraphicsContext, size: CGSize, seed: UInt64) {
        let dotSize: CGFloat = 4
        let cols = Int(size.width / dotSize)
        let rows = Int(size.height / dotSize)
        var rng = SimpleRNG(seed: seed)

        // Background
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

        let hue = hueRotation / 360.0
        let isTinted = hueRotation > 0.5 // effectively any nonzero hue

        for row in 0..<rows {
            for col in 0..<cols {
                let rand = rng.nextDouble()

                // Contrast maps brightness: low = mid-gray, high = full black/white
                let midPoint = 0.5
                let range = grainContrast
                let brightness = midPoint + (rand - 0.5) * range * 2

                let color: Color
                if isTinted {
                    color = Color(
                        hue: hue,
                        saturation: 0.6 * grainContrast,
                        brightness: brightness
                    )
                } else {
                    color = Color(white: brightness)
                }

                let rect = CGRect(
                    x: CGFloat(col) * dotSize,
                    y: CGFloat(row) * dotSize,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(Path(rect), with: .color(color))
            }
        }
    }
}

// MARK: - Simple deterministic RNG

/// Xorshift64-based PRNG for reproducible grain per frame.
private struct SimpleRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state &<< 13
        state ^= state &>> 7
        state ^= state &<< 17
        return state
    }

    mutating func nextDouble() -> Double {
        Double(next() & 0x1FFFFFFFFFFFFF) / Double(0x1FFFFFFFFFFFFF)
    }
}
