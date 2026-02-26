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
                        TileView(title: "Breathing", icon: "wind", enabled: true)
                    }
                    .accessibilityLabel("Breathing exercises")

                    // Static Audio tile
                    NavigationLink(destination: StaticAudioView()) {
                        TileView(title: "Static", icon: "waveform", enabled: true)
                    }
                    .accessibilityLabel("Static noise audio")

                    // Visual Training tile
                    NavigationLink(destination: VisualTrainingMenuView()) {
                        TileView(title: "Visual Training", icon: "eye.trianglebadge.exclamationmark", enabled: true)
                    }
                    .accessibilityLabel("Visual Training exercises")

                    // Symptom Simulator tile
                    NavigationLink(destination: SymptomSimulatorView()) {
                        TileView(title: "Simulator", icon: "sparkles.rectangle.stack", enabled: true)
                    }
                    .accessibilityLabel("Symptom Simulator")

                    // Research tile
                    NavigationLink(destination: ResearchView()) {
                        TileView(title: "Research", icon: "book.pages", enabled: true)
                    }
                    .accessibilityLabel("Research papers")
                }
                .padding()
            }
            .navigationTitle("Visual Snow Solace")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
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
