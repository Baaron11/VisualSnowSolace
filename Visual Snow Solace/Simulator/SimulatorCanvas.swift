// SimulatorCanvas.swift
// Visual Snow Solace
//
// Core Image based visual snow rendering canvas. Uses CIFilter random noise
// composited with a CIColorMatrix tint. Flicker is driven by a TimelineView.
// Peripheral static applies noise only to edge regions via a CIRadialGradient
// mask. Afterimage effect uses a brief white flash overlay faded with opacity.

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Simulator Canvas

struct SimulatorCanvas: View {
    let snowDensity: Double          // 0–100
    let flickerRate: Double          // 0–5 Hz (already safety-capped)
    let afterimagePersistence: AfterimageLevel
    let driftSpeed: Double           // 0–1
    let colorBiasRed: Double
    let colorBiasGreen: Double
    let colorBiasBlue: Double
    let peripheralStaticEnabled: Bool
    let isRunning: Bool
    let reduceMotion: Bool

    @State private var showAfterimage = false
    @State private var afterimageOpacity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                // Background
                Color.black

                if isRunning {
                    // Main snow noise layer
                    TimelineView(.animation(minimumInterval: frameInterval)) { timeline in
                        let seed = timeline.date.timeIntervalSinceReferenceDate
                        NoiseImageView(
                            seed: seed,
                            density: snowDensity,
                            driftSpeed: driftSpeed,
                            tintRed: colorBiasRed,
                            tintGreen: colorBiasGreen,
                            tintBlue: colorBiasBlue,
                            peripheralOnly: peripheralStaticEnabled,
                            size: size
                        )
                        .opacity(flickerOpacity(at: seed))
                    }

                    // Afterimage flash overlay
                    if showAfterimage {
                        Color.white
                            .opacity(afterimageOpacity)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .clipped()
        .onAppear { scheduleAfterimage() }
        .onChange(of: isRunning) { _, running in
            if running { scheduleAfterimage() }
        }
    }

    // MARK: - Frame Interval

    /// Minimum frame interval based on drift speed. Faster drift = more frames.
    private var frameInterval: TimeInterval {
        let base = 1.0 / 30.0  // 30 fps baseline
        let speedFactor = max(0.3, 1.0 - driftSpeed * 0.7)
        return base * speedFactor
    }

    // MARK: - Flicker

    /// Calculates opacity for flicker effect. When reduceMotion is on or
    /// flickerRate is 0, returns constant 1.0 (no flicker).
    private func flickerOpacity(at time: Double) -> Double {
        guard !reduceMotion, flickerRate > 0 else { return 1.0 }
        // Square wave flicker: on/off at the given Hz rate
        let cycle = time * flickerRate
        let phase = cycle - floor(cycle)
        return phase < 0.5 ? 1.0 : 0.3
    }

    // MARK: - Afterimage

    private func scheduleAfterimage() {
        guard isRunning else { return }
        // Trigger afterimage every 4–8 seconds
        let delay = Double.random(in: 4...8)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard isRunning else { return }
            triggerAfterimage()
            scheduleAfterimage()
        }
    }

    private func triggerAfterimage() {
        showAfterimage = true
        afterimageOpacity = afterimagePersistence.opacity
        withAnimation(.easeOut(duration: afterimagePersistence.duration)) {
            afterimageOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + afterimagePersistence.duration + 0.1) {
            showAfterimage = false
        }
    }
}

// MARK: - Noise Image View (Core Image Pipeline)

private struct NoiseImageView: View {
    let seed: Double
    let density: Double
    let driftSpeed: Double
    let tintRed: Double
    let tintGreen: Double
    let tintBlue: Double
    let peripheralOnly: Bool
    let size: CGSize

    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    var body: some View {
        let image = generateNoiseImage()
        Image(decorative: image, scale: 1.0)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
    }

    private func generateNoiseImage() -> CGImage {
        // Use a smaller render size for performance, then scale up
        let renderScale: CGFloat = 0.25
        let w = max(1, Int(size.width * renderScale))
        let h = max(1, Int(size.height * renderScale))

        // Random noise generator
        let noiseFilter = CIFilter.randomGenerator()

        guard var noiseImage = noiseFilter.outputImage else {
            return Self.fallbackImage(width: w, height: h)
        }

        // Crop to desired size
        noiseImage = noiseImage.cropped(to: CGRect(x: seed * driftSpeed * 100, y: seed * driftSpeed * 50, width: w, height: h))

        // Apply density as opacity via alpha scaling
        let densityAlpha = density / 100.0
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = noiseImage
        colorMatrix.rVector = CIVector(x: tintRed * densityAlpha, y: 0, z: 0, w: 0)
        colorMatrix.gVector = CIVector(x: 0, y: tintGreen * densityAlpha, z: 0, w: 0)
        colorMatrix.bVector = CIVector(x: 0, y: 0, z: tintBlue * densityAlpha, w: 0)
        colorMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: densityAlpha)
        colorMatrix.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)

        guard var tintedImage = colorMatrix.outputImage else {
            return Self.fallbackImage(width: w, height: h)
        }

        // Peripheral static: mask to show noise only at edges
        if peripheralOnly {
            let center = CIVector(x: CGFloat(w) / 2, y: CGFloat(h) / 2)
            let maxRadius = min(CGFloat(w), CGFloat(h)) * 0.5

            let gradient = CIFilter.radialGradient()
            gradient.center = center
            gradient.radius0 = Float(maxRadius * 0.4)   // Inner clear zone
            gradient.radius1 = Float(maxRadius)          // Outer noise zone
            gradient.color0 = CIColor(red: 0, green: 0, blue: 0, alpha: 0)
            gradient.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 1)

            if let maskImage = gradient.outputImage?.cropped(to: tintedImage.extent) {
                let blendFilter = CIFilter.multiplyCompositing()
                blendFilter.inputImage = tintedImage
                blendFilter.backgroundImage = maskImage
                if let masked = blendFilter.outputImage {
                    tintedImage = masked
                }
            }
        }

        guard let cgImage = Self.context.createCGImage(tintedImage, from: tintedImage.extent) else {
            return Self.fallbackImage(width: w, height: h)
        }

        return cgImage
    }

    /// Fallback 1×1 black pixel if CI pipeline fails.
    private static func fallbackImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil, width: max(width, 1), height: max(height, 1),
            bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: max(width, 1), height: max(height, 1)))
        return ctx.makeImage()!
    }
}
