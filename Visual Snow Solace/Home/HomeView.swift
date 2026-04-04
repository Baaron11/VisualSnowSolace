// HomeView.swift
// Visual Snow Solace
//
// Main hub screen with a 2×2 grid of feature tiles. Embedded in a
// NavigationStack so tiles can push detail views. A gear icon in the
// toolbar navigates to Settings.

import SwiftUI

struct HomeView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    // Breathing tile
                    NavigationLink(destination: BreathingView()) {
                        TileView(title: NSLocalizedString("home.breathing", comment: "Breathing tile title"), icon: "wind", enabled: true)
                    }
                    .accessibilityLabel(NSLocalizedString("home.breathing.accessibility", comment: "Breathing tile accessibility"))

                    // Static Audio tile
                    NavigationLink(destination: StaticAudioView()) {
                        TileView(title: NSLocalizedString("home.static", comment: "Static tile title"), icon: "waveform", enabled: true)
                    }
                    .accessibilityLabel(NSLocalizedString("home.static.accessibility", comment: "Static tile accessibility"))

                    // Visual Training tile
                    NavigationLink(destination: VisualTrainingMenuView()) {
                        TileView(title: NSLocalizedString("home.visualTraining", comment: "Visual Training tile title"), icon: "eye.trianglebadge.exclamationmark", enabled: true)
                    }
                    .accessibilityLabel(NSLocalizedString("home.visualTraining.accessibility", comment: "Visual Training tile accessibility"))

                    // Symptoms tile
                    NavigationLink(destination: SymptomGalleryView()) {
                        TileView(title: NSLocalizedString("home.symptoms", comment: "Symptoms tile title"), icon: "eye.trianglebadge.exclamationmark", enabled: true)
                    }
                    .accessibilityLabel(NSLocalizedString("home.symptoms.accessibility", comment: "Symptoms tile accessibility"))

                    // Research tile
                    NavigationLink(destination: ResearchView()) {
                        TileView(title: NSLocalizedString("home.research", comment: "Research tile title"), icon: "book.pages", enabled: true)
                    }
                    .accessibilityLabel(NSLocalizedString("home.research.accessibility", comment: "Research tile accessibility"))
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("home.title", comment: "Home screen navigation title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .accessibilityLabel(NSLocalizedString("home.settings.accessibility", comment: "Settings button accessibility"))
                    }
                }
            }
        }
    }
}

// MARK: - Tile View

private struct TileView: View {
    let title: String
    let icon: String
    let enabled: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(enabled ? .primary : .secondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(enabled ? .primary : .secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .opacity(enabled ? 1.0 : 0.5)
    }
}
