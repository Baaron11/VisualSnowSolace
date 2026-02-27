// VisualTrainingMenuView.swift
// Visual Snow Solace
//
// Menu screen listing available visual training exercises. Shows a
// one-time safety warning sheet before the user accesses any exercise
// for the first time in a session. Exercises are grouped into eye-movement
// and binocular/convergence sections.

import SwiftUI

struct VisualTrainingMenuView: View {
    @AppStorage("visualTraining.safetyShownThisLaunch") private var safetyDismissed = false
    @State private var showSafetySheet = false

    var body: some View {
        List {
            Section {
                NavigationLink(destination: LensModeView()) {
                    exerciseRow(
                        icon: "camera.filters",
                        title: "Lens Mode",
                        description: "Tinted camera overlays for light sensitivity"
                    )
                }
                .accessibilityLabel("Lens Mode exercise")

                NavigationLink(destination: SaccadesView()) {
                    exerciseRow(
                        icon: "arrow.left.arrow.right",
                        title: "Saccades",
                        description: "Rapid eye-movement training with a jumping dot"
                    )
                }
                .accessibilityLabel("Saccades exercise")

                NavigationLink(destination: SmoothPursuitView()) {
                    exerciseRow(
                        icon: "point.topleft.down.to.point.bottomright.curvepath",
                        title: "Smooth Pursuit",
                        description: "Track a dot along continuous paths"
                    )
                }
                .accessibilityLabel("Smooth Pursuit exercise")
            } header: {
                Text("Eye Movement Exercises")
            }

            Section {
                NavigationLink(destination: BrockStringView()) {
                    exerciseRow(
                        icon: "circle.grid.3x3",
                        title: "Brock String",
                        description: "Focus-shifting across three beads on a string"
                    )
                }
                .accessibilityLabel("Brock String exercise")

                NavigationLink(destination: PencilPushupsView()) {
                    exerciseRow(
                        icon: "pencil",
                        title: "Pencil Pushups",
                        description: "Track a pencil moving toward and away from you"
                    )
                }
                .accessibilityLabel("Pencil Pushups exercise")

                NavigationLink(destination: BarrelCardsView()) {
                    exerciseRow(
                        icon: "circle.circle",
                        title: "Barrel Cards",
                        description: "Focus through concentric rings at varying distances"
                    )
                }
                .accessibilityLabel("Barrel Cards exercise")

                NavigationLink(destination: SeptumCatView()) {
                    exerciseRow(
                        icon: "hand.point.up",
                        title: "Septum Cat",
                        description: "Observe physiological diplopia with a near finger"
                    )
                }
                .accessibilityLabel("Septum Cat exercise")

                NavigationLink(destination: LifesaverView()) {
                    exerciseRow(
                        icon: "circle.dashed",
                        title: "Lifesaver",
                        description: "Free-fusion exercise with side-by-side rings"
                    )
                }
                .accessibilityLabel("Lifesaver exercise")
            } header: {
                Text("Binocular & Convergence Exercises")
            }
        }
        .navigationTitle("Visual Training")
        .onAppear {
            if !safetyDismissed {
                showSafetySheet = true
            }
        }
        .sheet(isPresented: $showSafetySheet, onDismiss: {
            safetyDismissed = true
        }) {
            safetyWarningSheet
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Safety Warning

    private var safetyWarningSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)

                Text("Safety Notice")
                    .font(.title.bold())

                Text("These visual exercises are for informational and wellness purposes only. They are not a substitute for professional medical advice, diagnosis, or treatment.\n\nStop immediately if you experience discomfort, dizziness, or worsening symptoms. Consult your clinician before beginning any visual training program.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button {
                    showSafetySheet = false
                } label: {
                    Text("I Understand")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Dismiss safety notice")
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
