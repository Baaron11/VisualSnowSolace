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

    @AppStorage("visualStatic.visible") private var showVisualStatic: Bool = false
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
                Picker(NSLocalizedString("staticAudio.noiseType", comment: "Noise Type picker label"), selection: $noise.noiseType) {
                    ForEach(NoiseType.allCases) { type in
                        Text(localizedNoiseTypeName(type)).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(NSLocalizedString("staticAudio.noiseType.accessibility", comment: "Noise type picker accessibility"))

                // Volume slider
                HStack {
                    Text(String(format: NSLocalizedString("staticAudio.volume", comment: "Volume label"), Int(noise.volume * 100)))
                        .frame(width: 110, alignment: .leading)
                        .font(.subheadline)
                    Slider(value: $noise.volume, in: 0...1)
                        .accessibilityLabel(String(format: NSLocalizedString("staticAudio.volume.accessibility", comment: "Volume slider accessibility"), Int(noise.volume * 100)))
                }

                // Filter slider
                HStack {
                    Text(String(format: NSLocalizedString("staticAudio.filter", comment: "Filter label"), Int(noise.filterCutoff)))
                        .frame(width: 110, alignment: .leading)
                        .font(.subheadline)
                    Slider(value: $noise.filterCutoff, in: 200...20000)
                        .accessibilityLabel(String(format: NSLocalizedString("staticAudio.filter.accessibility", comment: "Filter slider accessibility"), Int(noise.filterCutoff)))
                }

                Toggle(NSLocalizedString("staticAudio.showVisualStatic", comment: "Show Visual Static toggle"), isOn: $showVisualStatic)

                if showVisualStatic {
                    VisualStaticView(
                        grainSpeed: $grainSpeed,
                        grainContrast: $grainContrast,
                        hueRotation: $grainHue,
                        showFullscreen: $showVisualStaticFullscreen,
                        showControls: false
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
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
                        .accessibilityLabel(NSLocalizedString("staticAudio.fullscreen.accessibility", comment: "Fullscreen button accessibility"))
                    }

                    HStack {
                        Text(NSLocalizedString("staticAudio.grainSpeed", comment: "Grain Speed label"))
                            .frame(width: 110, alignment: .leading)
                            .font(.subheadline)
                        Slider(value: $grainSpeed, in: 0.1...3.0)
                    }

                    HStack {
                        Text(NSLocalizedString("staticAudio.contrast", comment: "Contrast label"))
                            .frame(width: 110, alignment: .leading)
                            .font(.subheadline)
                        Slider(value: $grainContrast, in: 0.0...1.0)
                    }

                    HStack {
                        Text(NSLocalizedString("staticAudio.hue", comment: "Hue label"))
                            .frame(width: 110, alignment: .leading)
                            .font(.subheadline)
                        Slider(value: $grainHue, in: 0.0...360.0)
                    }
                }

                // Session timer
                if noise.isPlaying {
                    Text(String(format: NSLocalizedString("staticAudio.session", comment: "Session timer"), formatTime(sessionTime)))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                DisclaimerFooter()
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("staticAudio.title", comment: "Static Audio navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    noise.toggle()
                } label: {
                    Label(noise.isPlaying ? NSLocalizedString("staticAudio.pause", comment: "Pause button") : NSLocalizedString("staticAudio.play", comment: "Play button"),
                          systemImage: noise.isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(noise.isPlaying ? NSLocalizedString("staticAudio.pause.accessibility", comment: "Pause button accessibility") : NSLocalizedString("staticAudio.play.accessibility", comment: "Play button accessibility"))
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

    private func localizedNoiseTypeName(_ type: NoiseType) -> String {
        switch type {
        case .white: return NSLocalizedString("staticAudio.noiseType.white", comment: "White noise type")
        case .pink: return NSLocalizedString("staticAudio.noiseType.pink", comment: "Pink noise type")
        case .brown: return NSLocalizedString("staticAudio.noiseType.brown", comment: "Brown noise type")
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
