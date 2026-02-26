// SymptomSimulatorView.swift
// Visual Snow Solace
//
// Symptom simulator with adjustable parameters for visual snow characteristics.
// Includes mandatory seizure/symptom warning acknowledgment before first use,
// safety-capped flicker rate (max 5 Hz, disabled with Reduce Motion), a large
// persistent STOP button, and an auto-stop timer (default 30s, max 60s).

import SwiftUI

struct SymptomSimulatorView: View {
    @Environment(NoiseGenerator.self) private var noiseGenerator
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(AppSettings.self) private var appSettings

    // Acknowledgment gate — persists across launches
    @AppStorage("simulator.acknowledgmentAccepted") private var acknowledgmentAccepted = false
    @State private var showAcknowledgment = false

    // Simulator state
    @State private var isRunning = false
    @State private var remainingSeconds: Int = 30
    @State private var timerDuration: Int = 30     // user-configurable, max 60
    @State private var timer: Timer?

    // Parameters
    @State private var snowDensity: Double = 50
    @State private var flickerRate: Double = 0
    @State private var afterimagePersistence: AfterimageLevel = .medium
    @State private var driftSpeed: Double = 0.5
    @State private var colorBiasRed: Double = 1.0
    @State private var colorBiasGreen: Double = 1.0
    @State private var colorBiasBlue: Double = 1.0
    @State private var peripheralStaticEnabled = false
    @State private var audioHissEnabled = false

    // Presets
    @State private var presetStore = PresetStore()
    @State private var showSavePresetSheet = false
    @State private var showLoadPresetSheet = false

    /// True if flicker should be disabled (system or app reduce-motion setting).
    private var reduceMotion: Bool {
        systemReduceMotion || appSettings.reduceMotionOverride
    }

    /// The flicker rate capped to 5 Hz and forced to 0 when reduce motion is on.
    private var safeFlickerRate: Double {
        guard !reduceMotion else { return 0 }
        return min(max(flickerRate, 0), 5)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack(spacing: 0) {
                // Canvas area
                SimulatorCanvas(
                    snowDensity: snowDensity,
                    flickerRate: safeFlickerRate,
                    afterimagePersistence: afterimagePersistence,
                    driftSpeed: driftSpeed,
                    colorBiasRed: colorBiasRed,
                    colorBiasGreen: colorBiasGreen,
                    colorBiasBlue: colorBiasBlue,
                    peripheralStaticEnabled: peripheralStaticEnabled,
                    isRunning: isRunning,
                    reduceMotion: reduceMotion
                )
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // Timer display
                if isRunning {
                    Text("Auto-stop in \(remainingSeconds)s")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }

                // STOP button — always visible, never scrolls off
                stopButton
                    .padding(.top, 12)
                    .padding(.horizontal)

                // Parameter controls (scrollable)
                ScrollView {
                    VStack(spacing: 20) {
                        parameterControls
                        presetSection
                        timerSection
                    }
                    .padding()
                }

                // Pinned disclaimer footer
                DisclaimerFooter()
                    .padding(.bottom, 8)
            }
        }
        .navigationTitle("Symptom Simulator")
        .onAppear {
            if !acknowledgmentAccepted {
                showAcknowledgment = true
            }
        }
        .onDisappear {
            stopSimulation()
        }
        .sheet(isPresented: $showAcknowledgment) {
            acknowledgmentSheet
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showSavePresetSheet) {
            SavePresetSheet(store: presetStore) { preset in
                var p = preset
                p.snowDensity = snowDensity
                p.flickerRate = safeFlickerRate
                p.afterimagePersistence = afterimagePersistence
                p.driftSpeed = driftSpeed
                p.colorBiasRed = colorBiasRed
                p.colorBiasGreen = colorBiasGreen
                p.colorBiasBlue = colorBiasBlue
                p.peripheralStaticEnabled = peripheralStaticEnabled
                p.audioHissEnabled = audioHissEnabled
                presetStore.add(p)
            }
        }
        .sheet(isPresented: $showLoadPresetSheet) {
            LoadPresetSheet(store: presetStore) { preset in
                applyPreset(preset)
            }
        }
    }

    // MARK: - Stop Button

    private var stopButton: some View {
        Button {
            if isRunning {
                stopSimulation()
            } else {
                startSimulation()
            }
        } label: {
            HStack {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                Text(isRunning ? "STOP" : "START")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(isRunning ? .red : .green)
        .controlSize(.large)
        .accessibilityLabel(isRunning ? "Stop simulator" : "Start simulator")
    }

    // MARK: - Parameter Controls

    private var parameterControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Parameters")
                .font(.headline)

            // Snow density
            VStack(alignment: .leading) {
                Text("Snow Density: \(Int(snowDensity))%")
                    .font(.subheadline)
                Slider(value: $snowDensity, in: 0...100, step: 1)
                    .accessibilityLabel("Snow density, \(Int(snowDensity)) percent")
            }

            // Flicker rate
            VStack(alignment: .leading) {
                HStack {
                    Text("Flicker Rate: \(String(format: "%.1f", safeFlickerRate)) Hz")
                        .font(.subheadline)
                    if reduceMotion {
                        Text("(Disabled — Reduce Motion)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Slider(value: $flickerRate, in: 0...5, step: 0.1)
                    .disabled(reduceMotion)
                    .accessibilityLabel("Flicker rate, \(String(format: "%.1f", safeFlickerRate)) hertz")
            }

            // Afterimage persistence
            VStack(alignment: .leading) {
                Text("Afterimage Persistence")
                    .font(.subheadline)
                Picker("Afterimage", selection: $afterimagePersistence) {
                    ForEach(AfterimageLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Afterimage persistence level")
            }

            // Drift speed
            VStack(alignment: .leading) {
                Text("Drift Speed: \(String(format: "%.1f", driftSpeed))")
                    .font(.subheadline)
                Slider(value: $driftSpeed, in: 0...1, step: 0.1)
                    .accessibilityLabel("Drift speed, \(String(format: "%.1f", driftSpeed))")
            }

            // Color bias tint
            VStack(alignment: .leading) {
                Text("Color Bias Tint")
                    .font(.subheadline)
                HStack(spacing: 12) {
                    VStack {
                        Text("R").font(.caption2).foregroundStyle(.red)
                        Slider(value: $colorBiasRed, in: 0...1)
                            .tint(.red)
                            .accessibilityLabel("Red tint, \(String(format: "%.0f", colorBiasRed * 100)) percent")
                    }
                    VStack {
                        Text("G").font(.caption2).foregroundStyle(.green)
                        Slider(value: $colorBiasGreen, in: 0...1)
                            .tint(.green)
                            .accessibilityLabel("Green tint, \(String(format: "%.0f", colorBiasGreen * 100)) percent")
                    }
                    VStack {
                        Text("B").font(.caption2).foregroundStyle(.blue)
                        Slider(value: $colorBiasBlue, in: 0...1)
                            .tint(.blue)
                            .accessibilityLabel("Blue tint, \(String(format: "%.0f", colorBiasBlue * 100)) percent")
                    }
                }
            }

            // Toggles
            Toggle("Peripheral Static", isOn: $peripheralStaticEnabled)
                .font(.subheadline)
                .accessibilityLabel("Peripheral static toggle")

            Toggle("Audio Hiss", isOn: $audioHissEnabled)
                .font(.subheadline)
                .onChange(of: audioHissEnabled) { _, enabled in
                    if enabled && isRunning {
                        noiseGenerator.noiseType = .white
                        noiseGenerator.volume = 0.15
                        noiseGenerator.filterCutoff = 8000
                        noiseGenerator.start()
                    } else {
                        noiseGenerator.stop()
                    }
                }
                .accessibilityLabel("Audio hiss toggle")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Preset Section

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presets")
                .font(.headline)

            HStack(spacing: 12) {
                Button {
                    showSavePresetSheet = true
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Save current settings as preset")

                Button {
                    showLoadPresetSheet = true
                } label: {
                    Label("Load", systemImage: "folder.badge.gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(presetStore.presets.isEmpty)
                .accessibilityLabel("Load a saved preset")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auto-Stop Timer")
                .font(.headline)

            VStack(alignment: .leading) {
                Text("Duration: \(timerDuration)s")
                    .font(.subheadline)
                Slider(
                    value: Binding(
                        get: { Double(timerDuration) },
                        set: { timerDuration = Int($0) }
                    ),
                    in: 5...60,
                    step: 5
                )
                .disabled(isRunning)
                .accessibilityLabel("Auto-stop timer, \(timerDuration) seconds")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Simulation Control

    private func startSimulation() {
        remainingSeconds = timerDuration
        isRunning = true

        // Start audio hiss if enabled
        if audioHissEnabled {
            noiseGenerator.noiseType = .white
            noiseGenerator.volume = 0.15
            noiseGenerator.filterCutoff = 8000
            noiseGenerator.start()
        }

        // Auto-stop countdown
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                stopSimulation()
            }
        }
    }

    private func stopSimulation() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        remainingSeconds = timerDuration

        // Stop audio hiss
        if audioHissEnabled {
            noiseGenerator.stop()
        }
    }

    private func applyPreset(_ preset: SimulatorPreset) {
        snowDensity = preset.snowDensity
        flickerRate = preset.safeFlickerRate
        afterimagePersistence = preset.afterimagePersistence
        driftSpeed = preset.driftSpeed
        colorBiasRed = preset.colorBiasRed
        colorBiasGreen = preset.colorBiasGreen
        colorBiasBlue = preset.colorBiasBlue
        peripheralStaticEnabled = preset.peripheralStaticEnabled
        audioHissEnabled = preset.audioHissEnabled
    }

    // MARK: - Acknowledgment Sheet

    private var acknowledgmentSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.red)

                Text("Seizure & Symptom Warning")
                    .font(.title2.bold())

                Text("""
                    This simulator reproduces visual effects associated with \
                    Visual Snow Syndrome, including flickering, static noise, \
                    and afterimages.

                    **These effects may trigger seizures in people with \
                    photosensitive epilepsy or worsen symptoms for those with \
                    Visual Snow Syndrome or migraine.**

                    • Flicker rate is hard-capped at 5 Hz
                    • A large STOP button is always visible
                    • The simulation auto-stops after a set timer
                    • This is not a diagnostic or medical tool

                    If you feel any discomfort, stop immediately and consult \
                    your clinician.
                    """)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Button {
                    acknowledgmentAccepted = true
                    showAcknowledgment = false
                } label: {
                    Text("I Understand")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Acknowledge seizure and symptom warning")
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}

// MARK: - Save Preset Sheet

private struct SavePresetSheet: View {
    let store: PresetStore
    let onSave: (SimulatorPreset) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var matchesMySymptoms = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Preset name", text: $name)
                        .accessibilityLabel("Preset name text field")
                }
                Section {
                    Toggle("Matches My Symptoms", isOn: $matchesMySymptoms)
                        .accessibilityLabel("Mark preset as matching your symptoms")
                }
            }
            .navigationTitle("Save Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var preset = SimulatorPreset(name: name)
                        preset.matchesMySymptoms = matchesMySymptoms
                        onSave(preset)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Load Preset Sheet

private struct LoadPresetSheet: View {
    let store: PresetStore
    let onLoad: (SimulatorPreset) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.presets) { preset in
                    Button {
                        onLoad(preset)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.name)
                                    .font(.body.bold())
                                    .foregroundStyle(.primary)
                                Text("Density \(Int(preset.snowDensity))% · Flicker \(String(format: "%.1f", preset.safeFlickerRate)) Hz")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if preset.matchesMySymptoms {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .accessibilityLabel("Matches your symptoms")
                            }
                        }
                    }
                    .accessibilityLabel("Load preset \(preset.name)")
                }
                .onDelete { offsets in
                    store.delete(at: offsets)
                }
            }
            .navigationTitle("Load Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
