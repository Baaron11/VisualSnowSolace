// VisualTrainingMenuView.swift
// Visual Snow Solace
//
// Menu screen listing available visual training exercises. Shows a
// one-time safety warning sheet before the user accesses any exercise
// for the first time in a session. Convergence is listed as "coming soon".

import SwiftUI

struct VisualTrainingMenuView: View {
    @AppStorage("visualTraining.safetyShownThisLaunch") private var safetyDismissed = false
    @State private var showSafetySheet = false

    var body: some View {
        List {
            Section {
                NavigationLink(destination: LensModeView()) {
                    Label("Lens Mode", systemImage: "camera.filters")
                }
                .accessibilityLabel("Lens Mode exercise")

                NavigationLink(destination: SaccadesView()) {
                    Label("Saccades", systemImage: "arrow.left.arrow.right")
                }
                .accessibilityLabel("Saccades exercise")

                NavigationLink(destination: SmoothPursuitView()) {
                    Label("Smooth Pursuit", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                }
                .accessibilityLabel("Smooth Pursuit exercise")
            } header: {
                Text("Exercises")
            }

            Section {
                HStack {
                    Label("Convergence", systemImage: "arrow.triangle.merge")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .accessibilityLabel("Convergence, coming soon")
            } header: {
                Text("Upcoming")
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
