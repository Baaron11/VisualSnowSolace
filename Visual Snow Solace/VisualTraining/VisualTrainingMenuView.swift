// VisualTrainingMenuView.swift
// Visual Snow Solace
//
// Menu screen listing available visual training exercises. Shows a
// one-time safety warning sheet before the user accesses any exercise
// for the first time in a session. Exercises are grouped into eye-movement
// and binocular/convergence sections.

import Foundation
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
                        title: NSLocalizedString("trainingMenu.lensMode.title", comment: "Lens Mode exercise title"),
                        description: NSLocalizedString("trainingMenu.lensMode.description", comment: "Lens Mode exercise description")
                    )
                }
                .accessibilityLabel(NSLocalizedString("trainingMenu.lensMode.accessibility", comment: "Accessibility label for Lens Mode exercise"))
            } header: {
                Text(NSLocalizedString("trainingMenu.section.eyeMovement", comment: "Eye Movement Exercises section header"))
            }

            Section {
                NavigationLink(destination: BrockStringView()) {
                    exerciseRow(
                        icon: "circle.grid.3x3",
                        title: NSLocalizedString("trainingMenu.brockString.title", comment: "Brock String exercise title"),
                        description: NSLocalizedString("trainingMenu.brockString.description", comment: "Brock String exercise description")
                    )
                }
                .accessibilityLabel(NSLocalizedString("trainingMenu.brockString.accessibility", comment: "Accessibility label for Brock String exercise"))

                NavigationLink(destination: PencilPushupsView()) {
                    exerciseRow(
                        icon: "pencil",
                        title: NSLocalizedString("trainingMenu.pencilPushups.title", comment: "Pencil Pushups exercise title"),
                        description: NSLocalizedString("trainingMenu.pencilPushups.description", comment: "Pencil Pushups exercise description")
                    )
                }
                .accessibilityLabel(NSLocalizedString("trainingMenu.pencilPushups.accessibility", comment: "Accessibility label for Pencil Pushups exercise"))

                NavigationLink(destination: BarrelCardsView()) {
                    exerciseRow(
                        icon: "circle.circle",
                        title: NSLocalizedString("trainingMenu.barrelCards.title", comment: "Barrel Cards exercise title"),
                        description: NSLocalizedString("trainingMenu.barrelCards.description", comment: "Barrel Cards exercise description")
                    )
                }
                .accessibilityLabel(NSLocalizedString("trainingMenu.barrelCards.accessibility", comment: "Accessibility label for Barrel Cards exercise"))

                NavigationLink(destination: ConvergenceStereogramView()) {
                    exerciseRow(
                        icon: "hand.point.up",
                        title: NSLocalizedString("trainingMenu.convergenceStereogram.title", comment: "Convergence Stereogram exercise title"),
                        description: NSLocalizedString("trainingMenu.convergenceStereogram.description", comment: "Convergence Stereogram exercise description")
                    )
                }
                .accessibilityLabel(NSLocalizedString("trainingMenu.convergenceStereogram.accessibility", comment: "Accessibility label for Convergence Stereogram exercise"))

                NavigationLink(destination: LifesaverView()) {
                    exerciseRow(
                        icon: "circle.dashed",
                        title: NSLocalizedString("trainingMenu.lifesaver.title", comment: "Lifesaver exercise title"),
                        description: NSLocalizedString("trainingMenu.lifesaver.description", comment: "Lifesaver exercise description")
                    )
                }
                .accessibilityLabel(NSLocalizedString("trainingMenu.lifesaver.accessibility", comment: "Accessibility label for Lifesaver exercise"))
            } header: {
                Text(NSLocalizedString("trainingMenu.section.binocular", comment: "Binocular & Convergence Exercises section header"))
            }

            Section {
                NavigationLink(destination: HartChartView()) {
                    exerciseRow(
                        icon: "circle.grid.3x3",
                        title: NSLocalizedString("trainingMenu.hartChart.title", comment: "Hart Chart exercise title"),
                        description: NSLocalizedString("trainingMenu.hartChart.description", comment: "Hart Chart exercise description")
                    )
                }
                .accessibilityLabel(NSLocalizedString("trainingMenu.hartChart.accessibility", comment: "Accessibility label for Hart Chart exercise"))

                NavigationLink(destination: MichiganTrackingView()) {
                    exerciseRow(
                        icon: "text.alignleft",
                        title: NSLocalizedString("trainingMenu.michiganTracking.title", comment: "Michigan Tracking exercise title"),
                        description: NSLocalizedString("trainingMenu.michiganTracking.description", comment: "Michigan Tracking exercise description")
                    )
                }
                .accessibilityLabel(NSLocalizedString("trainingMenu.michiganTracking.accessibility", comment: "Accessibility label for Michigan Tracking exercise"))
            } header: {
                Text(NSLocalizedString("trainingMenu.section.hartChartTracking", comment: "Hart Chart & Tracking section header"))
            }

            Section {
                NavigationLink(destination: RedGreenWordView()) {
                    exerciseRow(
                        icon: "eyeglasses",
                        title: NSLocalizedString("trainingMenu.redGreenWordTraining.title", comment: "Red/Green Word Training exercise title"),
                        description: NSLocalizedString("trainingMenu.redGreenWordTraining.description", comment: "Red/Green Word Training exercise description")
                    )
                }
                .accessibilityLabel(NSLocalizedString("trainingMenu.redGreenWordTraining.accessibility", comment: "Accessibility label for Red/Green Word Training exercise"))
            } header: {
                Text(NSLocalizedString("trainingMenu.section.redGreenTraining", comment: "Red/Green Training section header"))
            }
        }
        .navigationTitle(NSLocalizedString("trainingMenu.title", comment: "Visual Training navigation title"))
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

                Text(NSLocalizedString("trainingMenu.safety.title", comment: "Safety warning sheet title"))
                    .font(.title.bold())

                Text(NSLocalizedString("trainingMenu.safety.body", comment: "Safety warning sheet body text with two paragraphs separated by newlines"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button {
                    showSafetySheet = false
                } label: {
                    Text(NSLocalizedString("trainingMenu.safety.dismiss", comment: "Safety warning dismiss button title"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel(NSLocalizedString("trainingMenu.safety.dismiss.accessibility", comment: "Accessibility label for dismiss safety notice button"))
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
