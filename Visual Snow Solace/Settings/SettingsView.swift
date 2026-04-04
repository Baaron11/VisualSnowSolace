// SettingsView.swift
// Visual Snow Solace
//
// App settings form with appearance, motion, breathing preset, and about
// sections. All settings persist through AppSettings (UserDefaults-backed).

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            // Appearance section
            Section(NSLocalizedString("settings.appearance", comment: "Appearance section header")) {
                Picker(NSLocalizedString("settings.appearance.theme", comment: "Theme picker label"), selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .accessibilityLabel(NSLocalizedString("settings.appearance.theme.accessibility", comment: "Theme picker accessibility"))
            }

            // Motion section
            Section(NSLocalizedString("settings.motion", comment: "Motion section header")) {
                Toggle(NSLocalizedString("settings.motion.reduceMotion", comment: "Reduce Motion toggle label"), isOn: $settings.reduceMotionOverride)
                    .accessibilityLabel(NSLocalizedString("settings.motion.reduceMotion.accessibility", comment: "Reduce Motion toggle accessibility"))

                Text(NSLocalizedString("settings.motion.description", comment: "Reduce Motion description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Breathing section
            Section(NSLocalizedString("settings.breathing", comment: "Breathing section header")) {
                Picker(NSLocalizedString("settings.breathing.defaultPreset", comment: "Default Preset picker label"), selection: $settings.defaultBreathingPreset) {
                    ForEach(BreathingPreset.allCases) { preset in
                        Text(preset.localizedName).tag(preset)
                    }
                }
                .accessibilityLabel(NSLocalizedString("settings.breathing.defaultPreset.accessibility", comment: "Default Preset picker accessibility"))
            }

            // About section
            Section(NSLocalizedString("settings.about", comment: "About section header")) {
                LabeledContent(NSLocalizedString("settings.about.version", comment: "Version label"), value: appVersion)
                    .accessibilityLabel(String(format: NSLocalizedString("settings.about.appVersion.accessibility", comment: "App version accessibility"), appVersion))

                Text(NSLocalizedString("settings.about.description", comment: "About section description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(NSLocalizedString("settings.title", comment: "Settings navigation title"))
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
