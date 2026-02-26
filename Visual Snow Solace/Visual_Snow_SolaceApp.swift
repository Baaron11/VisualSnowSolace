// Visual_Snow_SolaceApp.swift
// Visual Snow Solace
//
// App entry point. Injects shared AppSettings and NoiseGenerator into the
// environment so all views can access them. Applies the user's preferred
// color scheme from settings.

import SwiftUI

@main
struct Visual_Snow_SolaceApp: App {
    @State private var settings = AppSettings()
    @State private var noiseGenerator = NoiseGenerator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(noiseGenerator)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
    }
}
