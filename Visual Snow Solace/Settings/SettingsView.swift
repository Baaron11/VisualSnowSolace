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
            Section("Appearance") {
                Picker("Theme", selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .accessibilityLabel("App theme")
            }

            // Motion section
            Section("Motion") {
                Toggle("Reduce Motion", isOn: $settings.reduceMotionOverride)
                    .accessibilityLabel("Override reduce motion setting")

                Text("When enabled, breathing animations are replaced with text countdowns. This supplements the system Reduce Motion setting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Breathing section
            Section("Breathing") {
                Picker("Default Preset", selection: $settings.defaultBreathingPreset) {
                    ForEach(BreathingPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .accessibilityLabel("Default breathing preset")
            }

            // About section
            Section("About") {
                LabeledContent("Version", value: appVersion)
                    .accessibilityLabel("App version \(appVersion)")

                Text("Visual Snow Syndrome Solace is designed to provide comfort tools for people experiencing visual snow syndrome. Not a medical device. For informational use only. Consult your clinician before starting any new wellness routine.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
