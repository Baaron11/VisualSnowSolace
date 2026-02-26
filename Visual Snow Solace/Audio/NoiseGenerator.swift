// NoiseGenerator.swift
// Visual Snow Solace
//
// Audio engine wrapper that generates white, pink, and brown noise using
// AVAudioEngine and AVAudioSourceNode. Designed to work on both real devices
// and the simulator (audio output only).
//
// Noise algorithms:
//   - White: uniform random samples in [-1, 1]
//   - Pink:  Voss-McCartney algorithm — multiple white noise sources updated
//            at different octave rates, approximating a 1/f power spectrum.
//            Reference: https://www.firstpr.com.au/dsp/pink-noise/
//   - Brown: running integral (cumulative sum) of white noise, clamped to
//            [-1, 1]. Models Brownian motion / random walk.
//            Reference: https://en.wikipedia.org/wiki/Brownian_noise

import AVFoundation
import SwiftUI

// MARK: - Noise Type

enum NoiseType: String, CaseIterable, Identifiable {
    case white = "White"
    case pink = "Pink"
    case brown = "Brown"
    var id: String { rawValue }
}

// MARK: - Render State (shared between main thread and audio render thread)

/// Thread-safe state container accessed from both the main actor and the
/// real-time audio render callback. The noiseType enum is a single byte;
/// reads and writes are naturally atomic on ARM. The pink/brown generation
/// state is only mutated from the audio render thread. A brief race during
/// type change is aurally imperceptible for noise signals.
private final class RenderState: @unchecked Sendable {
    var noiseType: NoiseType = .white

    // Pink noise — Voss-McCartney state
    var pinkRows = [Float](repeating: 0, count: 16)
    var pinkRunningSum: Float = 0
    var pinkIndex: Int = 0

    // Brown noise — integration state
    var brownLastOutput: Float = 0

    func reset() {
        pinkRows = [Float](repeating: 0, count: 16)
        pinkRunningSum = 0
        pinkIndex = 0
        brownLastOutput = 0
    }

    /// Voss-McCartney pink noise: update one row per sample based on
    /// trailing zeros of the sample counter, then return the normalized sum.
    func nextPinkSample() -> Float {
        let index = pinkIndex
        pinkIndex += 1

        // Determine which row to update based on trailing zeros of index
        var k = 0
        var n = index
        if n > 0 {
            while (n & 1) == 0 && k < pinkRows.count - 1 {
                k += 1
                n >>= 1
            }
        }

        pinkRunningSum -= pinkRows[k]
        let newValue = Float.random(in: -1...1)
        pinkRunningSum += newValue
        pinkRows[k] = newValue

        // Normalize by number of rows and add a white noise component for
        // high-frequency content
        let numRows = Float(pinkRows.count)
        return (pinkRunningSum / numRows + Float.random(in: -1...1)) / (numRows / (numRows - 1))
    }

    /// Brown noise: integrate white noise with a small step, clamp output.
    func nextBrownSample() -> Float {
        brownLastOutput += Float.random(in: -0.1...0.1)
        brownLastOutput = min(1, max(-1, brownLastOutput))
        return brownLastOutput
    }
}

// MARK: - Noise Generator

@Observable
class NoiseGenerator {
    var isPlaying = false

    var volume: Float = 0.5 {
        didSet { engine?.mainMixerNode.outputVolume = volume }
    }

    var noiseType: NoiseType = .white {
        didSet {
            renderState.noiseType = noiseType
            // Reset generation state to avoid artifacts from prior algorithm
            renderState.reset()
        }
    }

    /// Low-pass filter cutoff in Hz, range 200–20000.
    var filterCutoff: Float = 20000 {
        didSet {
            guard let band = eq?.bands.first else { return }
            band.frequency = filterCutoff
        }
    }

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var eq: AVAudioUnitEQ?
    private let renderState = RenderState()
    private var interruptionObserver: NSObjectProtocol?

    deinit {
        stop()
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Playback Control

    func start() {
        guard !isPlaying else { return }
        configureAudioSession()
        setupEngine()
        do {
            try engine?.start()
            isPlaying = true
        } catch {
            print("NoiseGenerator: failed to start engine — \(error.localizedDescription)")
        }
    }

    func stop() {
        engine?.stop()
        engine = nil
        sourceNode = nil
        eq = nil
        isPlaying = false
    }

    func toggle() {
        if isPlaying { stop() } else { start() }
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        let engine = AVAudioEngine()
        // Force unwrap is safe: standard 44.1 kHz mono Float32 PCM format
        // always succeeds with valid parameters.
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        let state = renderState
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let currentType = state.noiseType
            for buffer in abl {
                guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                for frame in 0..<Int(frameCount) {
                    switch currentType {
                    case .white:
                        data[frame] = Float.random(in: -1...1)
                    case .pink:
                        data[frame] = state.nextPinkSample()
                    case .brown:
                        data[frame] = state.nextBrownSample()
                    }
                }
            }
            return noErr
        }

        let equalizer = AVAudioUnitEQ(numberOfBands: 1)
        if let band = equalizer.bands.first {
            band.filterType = .lowPass
            band.frequency = filterCutoff
            band.bandwidth = 1.0
            band.bypass = false
        }

        engine.attach(node)
        engine.attach(equalizer)
        engine.connect(node, to: equalizer, format: format)
        engine.connect(equalizer, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = volume

        self.engine = engine
        self.sourceNode = node
        self.eq = equalizer
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        #if os(iOS) || os(visionOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("NoiseGenerator: audio session setup failed — \(error.localizedDescription)")
        }
        observeInterruptions()
        #endif
    }

    private func observeInterruptions() {
        #if os(iOS) || os(visionOS)
        guard interruptionObserver == nil else { return }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            switch type {
            case .began:
                self.isPlaying = false
            case .ended:
                let optionsValue = (info[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    try? self.engine?.start()
                    self.isPlaying = true
                }
            @unknown default:
                break
            }
        }
        #endif
    }
}
