// HomeView.swift
// Visual Snow Solace
//
// Main hub screen with a 2×2 grid of feature tiles. Embedded in a
// NavigationStack so tiles can push detail views. A gear icon in the
// toolbar navigates to Settings.

import SwiftUI

struct HomeView: View {
    @State private var showComingSoonAlert = false
    @State private var comingSoonFeature = ""

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

                    // Visual Training — disabled / coming soon
                    Button {
                        comingSoonFeature = "Visual Training"
                        showComingSoonAlert = true
                    } label: {
                        TileView(title: "Visual Training", icon: "eye.trianglebadge.exclamationmark", enabled: false)
                    }
                    .accessibilityLabel("Visual Training, coming soon")

                    // Research — disabled / coming soon
                    Button {
                        comingSoonFeature = "Research"
                        showComingSoonAlert = true
                    } label: {
                        TileView(title: "Research", icon: "book.pages", enabled: false)
                    }
                    .accessibilityLabel("Research, coming soon")
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
            .alert("Coming in Phase 2", isPresented: $showComingSoonAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(comingSoonFeature) will be available in a future update.")
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
