// StaticAudioView.swift
// Visual Snow Solace
//
// User interface for the noise generator. Lets the user pick a noise type
// (white, pink, brown), adjust volume and a low-pass filter cutoff, and
// toggle playback.

import SwiftUI

struct StaticAudioView: View {
    @Environment(NoiseGenerator.self) private var noise

    var body: some View {
        @Bindable var noise = noise

        VStack(spacing: 32) {
            // Noise type picker
            Picker("Noise Type", selection: $noise.noiseType) {
                ForEach(NoiseType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Noise type picker")

            // Volume slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Volume: \(Int(noise.volume * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Slider(value: $noise.volume, in: 0...1)
                    .accessibilityLabel("Volume, \(Int(noise.volume * 100)) percent")
            }

            // Filter slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Filter Cutoff: \(Int(noise.filterCutoff)) Hz")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Slider(value: $noise.filterCutoff, in: 200...20000)
                    .accessibilityLabel("Low pass filter cutoff, \(Int(noise.filterCutoff)) hertz")
            }

            Spacer()

            // Play/Pause button
            Button {
                noise.toggle()
            } label: {
                Label(noise.isPlaying ? "Pause" : "Play",
                      systemImage: noise.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel(noise.isPlaying ? "Pause noise" : "Play noise")

            Spacer()

            DisclaimerFooter()
        }
        .padding()
        .navigationTitle("Static Audio")
        .onDisappear {
            noise.stop()
        }
    }
}
