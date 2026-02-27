// StaticAudioView.swift
// Visual Snow Solace
//
// User interface for the noise generator. Lets the user pick a noise type
// (white, pink, brown), adjust volume and a low-pass filter cutoff, and
// toggle playback.

import SwiftUI
internal import Combine

struct StaticAudioView: View {
    @Environment(NoiseGenerator.self) private var noise

    @AppStorage("visualStatic.speed") private var grainSpeed: Double = 1.0
    @AppStorage("visualStatic.contrast") private var grainContrast: Double = 0.5
    @AppStorage("visualStatic.hue") private var grainHue: Double = 0.0
    @State private var showVisualStaticFullscreen = false
    @State private var sessionTime: TimeInterval = 0

    var body: some View {
        @Bindable var noise = noise

        ScrollView {
            VStack(spacing: 20) {
                // Noise type picker
                Picker("Noise Type", selection: $noise.noiseType) {
                    ForEach(NoiseType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Noise type picker")

                // Volume slider
                HStack {
                    Text("Volume: \(Int(noise.volume * 100))%")
                        .frame(width: 110, alignment: .leading)
                        .font(.subheadline)
                    Slider(value: $noise.volume, in: 0...1)
                        .accessibilityLabel("Volume, \(Int(noise.volume * 100)) percent")
                }

                // Filter slider
                HStack {
                    Text("Filter: \(Int(noise.filterCutoff)) Hz")
                        .frame(width: 110, alignment: .leading)
                        .font(.subheadline)
                    Slider(value: $noise.filterCutoff, in: 200...20000)
                        .accessibilityLabel("Low pass filter cutoff, \(Int(noise.filterCutoff)) hertz")
                }

                // Visual Static canvas (always visible, condensed)
                VisualStaticView(
                    grainSpeed: $grainSpeed,
                    grainContrast: $grainContrast,
                    hueRotation: $grainHue,
                    showFullscreen: $showVisualStaticFullscreen
                )
                .frame(height: 180)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        showVisualStaticFullscreen = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.footnote)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(8)
                    .accessibilityLabel("Show visual static fullscreen")
                }

                HStack {
                    Text("Grain Speed")
                        .frame(width: 110, alignment: .leading)
                        .font(.subheadline)
                    Slider(value: $grainSpeed, in: 0.1...3.0)
                }

                HStack {
                    Text("Contrast")
                        .frame(width: 110, alignment: .leading)
                        .font(.subheadline)
                    Slider(value: $grainContrast, in: 0.0...1.0)
                }

                HStack {
                    Text("Hue")
                        .frame(width: 110, alignment: .leading)
                        .font(.subheadline)
                    Slider(value: $grainHue, in: 0.0...360.0)
                }

                // Session timer
                if noise.isPlaying {
                    Text("Session: \(formatTime(sessionTime))")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                DisclaimerFooter()
            }
            .padding()
        }
        .navigationTitle("Static Audio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    noise.toggle()
                } label: {
                    Label(noise.isPlaying ? "Pause" : "Play",
                          systemImage: noise.isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(noise.isPlaying ? "Pause noise" : "Play noise")
            }
        }
        .onDisappear {
            noise.stop()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard noise.isPlaying else { return }
            sessionTime += 1
        }
        .onChange(of: noise.isPlaying) { _, isPlaying in
            if isPlaying {
                sessionTime = 0
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
