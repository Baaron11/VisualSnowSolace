// SimulatorPreset.swift
// Visual Snow Solace
//
// Codable preset model for the Symptom Simulator. Each preset stores a full
// set of simulator parameters so users can save, reload, and share their
// configurations. Presets are persisted as a JSON array in UserDefaults.

import Foundation
import SwiftUI

// MARK: - Afterimage Persistence Level

enum AfterimageLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    var id: String { rawValue }

    /// Opacity for the afterimage flash overlay.
    var opacity: Double {
        switch self {
        case .low: return 0.15
        case .medium: return 0.35
        case .high: return 0.6
        }
    }

    /// Duration the afterimage remains visible (seconds).
    var duration: Double {
        switch self {
        case .low: return 0.3
        case .medium: return 0.7
        case .high: return 1.2
        }
    }
}

// MARK: - Simulator Preset

struct SimulatorPreset: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String

    // Visual parameters
    var snowDensity: Double = 50          // 0–100
    var flickerRate: Double = 0           // 0–5 Hz (hard cap enforced)
    var afterimagePersistence: AfterimageLevel = .medium
    var driftSpeed: Double = 0.5          // 0–1 normalized
    var colorBiasRed: Double = 1.0        // 0–1 tint component
    var colorBiasGreen: Double = 1.0      // 0–1 tint component
    var colorBiasBlue: Double = 1.0       // 0–1 tint component

    // Region toggles
    var peripheralStaticEnabled: Bool = false
    var audioHissEnabled: Bool = false

    // User flag
    var matchesMySymptoms: Bool = false

    /// Safety-capped flicker rate. Guarantees the value never exceeds 5 Hz.
    var safeFlickerRate: Double {
        min(max(flickerRate, 0), 5)
    }
}

// MARK: - Preset Store

@Observable
class PresetStore {
    var presets: [SimulatorPreset] = []

    private let storageKey = "simulatorPresets"

    init() {
        load()
    }

    func add(_ preset: SimulatorPreset) {
        presets.insert(preset, at: 0)
        save()
    }

    func update(_ preset: SimulatorPreset) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index] = preset
        save()
    }

    func delete(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            presets = try JSONDecoder().decode([SimulatorPreset].self, from: data)
        } catch {
            print("PresetStore: failed to decode presets — \(error.localizedDescription)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(presets)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("PresetStore: failed to encode presets — \(error.localizedDescription)")
        }
    }
}
