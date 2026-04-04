// AppSettings.swift
// Visual Snow Solace
//
// Central settings store for the app. Uses @Observable (Observation framework)
// since the project deployment target is iOS 26.2, well above the iOS 17
// minimum required for @Observable. All preferences persist via UserDefaults.

import SwiftUI

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .system: return NSLocalizedString("settings.appearance.system", comment: "System appearance mode")
        case .light: return NSLocalizedString("settings.appearance.light", comment: "Light appearance mode")
        case .dark: return NSLocalizedString("settings.appearance.dark", comment: "Dark appearance mode")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Breathing Preset

struct BreathingPhase {
    let name: String
    let duration: TimeInterval
    let targetScale: CGFloat
}

enum BreathingPreset: String, CaseIterable, Identifiable {
    case box = "Box (4-4-4-4)"
    case fourSevenEight = "4-7-8"
    case paced = "Paced (5-5)"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .box: return NSLocalizedString("appSettings.preset.box", comment: "Box breathing preset name")
        case .fourSevenEight: return NSLocalizedString("appSettings.preset.fourSevenEight", comment: "4-7-8 breathing preset name")
        case .paced: return NSLocalizedString("appSettings.preset.paced", comment: "Paced breathing preset name")
        }
    }

    var phases: [BreathingPhase] {
        switch self {
        case .box:
            return [
                BreathingPhase(name: NSLocalizedString("appSettings.breathing.inhale", comment: "Inhale phase"), duration: 4, targetScale: 1.5),
                BreathingPhase(name: NSLocalizedString("appSettings.breathing.hold", comment: "Hold phase"), duration: 4, targetScale: 1.5),
                BreathingPhase(name: NSLocalizedString("appSettings.breathing.exhale", comment: "Exhale phase"), duration: 4, targetScale: 0.6),
                BreathingPhase(name: NSLocalizedString("appSettings.breathing.hold", comment: "Hold phase"), duration: 4, targetScale: 0.6),
            ]
        case .fourSevenEight:
            return [
                BreathingPhase(name: NSLocalizedString("appSettings.breathing.inhale", comment: "Inhale phase"), duration: 4, targetScale: 1.5),
                BreathingPhase(name: NSLocalizedString("appSettings.breathing.hold", comment: "Hold phase"), duration: 7, targetScale: 1.5),
                BreathingPhase(name: NSLocalizedString("appSettings.breathing.exhale", comment: "Exhale phase"), duration: 8, targetScale: 0.6),
            ]
        case .paced:
            return [
                BreathingPhase(name: NSLocalizedString("appSettings.breathing.inhale", comment: "Inhale phase"), duration: 5, targetScale: 1.5),
                BreathingPhase(name: NSLocalizedString("appSettings.breathing.exhale", comment: "Exhale phase"), duration: 5, targetScale: 0.6),
            ]
        }
    }
}

// MARK: - App Settings

@Observable
class AppSettings {

    var appearance: AppearanceMode {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    var reduceMotionOverride: Bool {
        didSet { UserDefaults.standard.set(reduceMotionOverride, forKey: Keys.reduceMotion) }
    }

    var defaultBreathingPreset: BreathingPreset {
        didSet { UserDefaults.standard.set(defaultBreathingPreset.rawValue, forKey: Keys.breathingPreset) }
    }

    init() {
        let defaults = UserDefaults.standard
        self.appearance = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        self.reduceMotionOverride = defaults.bool(forKey: Keys.reduceMotion)
        self.defaultBreathingPreset = BreathingPreset(rawValue: defaults.string(forKey: Keys.breathingPreset) ?? "") ?? .box
    }

    private enum Keys {
        static let appearance = "appSettings.appearance"
        static let reduceMotion = "appSettings.reduceMotionOverride"
        static let breathingPreset = "appSettings.defaultBreathingPreset"
    }
}
