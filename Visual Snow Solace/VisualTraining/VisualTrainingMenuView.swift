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

                NavigationLink(destination: ConvergenceStereogramView()) {
                    exerciseRow(
                        icon: "hand.point.up",
                        title: "Convergence Stereogram",
                        description: "Use stereogram images to train convergence and fusion."
                    )
                }
                .accessibilityLabel("Convergence Stereogram exercise")

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

            Section {
                NavigationLink(destination: HartChartView()) {
                    exerciseRow(
                        icon: "circle.grid.3x3",
                        title: "Hart Chart",
                        description: "Distance and near letter charts for focus-shifting"
                    )
                }
                .accessibilityLabel("Hart Chart exercise")

                NavigationLink(destination: MichiganTrackingView()) {
                    exerciseRow(
                        icon: "text.alignleft",
                        title: "Michigan Tracking",
                        description: "Find and circle letters A–Z in a random paragraph"
                    )
                }
                .accessibilityLabel("Michigan Tracking exercise")
            } header: {
                Text("Hart Chart & Tracking")
            }

            Section {
                NavigationLink(destination: PostItSaccadesView()) {
                    exerciseRow(
                        icon: "note.text",
                        title: "Post-It Saccades",
                        description: "Real-world saccade training with sticky-note targets"
                    )
                }
                .accessibilityLabel("Post-It Saccades exercise")

                NavigationLink(destination: HandheldPencilSaccadesView()) {
                    exerciseRow(
                        icon: "pencil.and.list.clipboard",
                        title: "Handheld Pencil Saccades",
                        description: "Saccades with background distractors and a pencil target"
                    )
                }
                .accessibilityLabel("Handheld Pencil Saccades exercise")

                NavigationLink(destination: WayneSaccadicFixatorView()) {
                    exerciseRow(
                        icon: "circle.grid.3x3.fill",
                        title: "Wayne Saccadic Fixator",
                        description: "Tap lit targets in a grid for speed and accuracy"
                    )
                }
                .accessibilityLabel("Wayne Saccadic Fixator exercise")
            } header: {
                Text("Saccadic Training")
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
