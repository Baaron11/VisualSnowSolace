// SymptomSimulatorView.swift
// Visual Snow Solace
//
// Symptom education gallery presenting visual and non-visual symptoms
// associated with Visual Snow Syndrome, with image placeholders and
// detailed descriptions.

import SwiftUI

struct SymptomGalleryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Disclaimer banner
                disclaimerBanner

                // Section 1: Visual Symptoms
                sectionHeader(NSLocalizedString("symptoms.section.visual", comment: ""))

                SymptomCard(
                    title: NSLocalizedString("symptoms.visualSnow.title", comment: ""),
                    imageNames: ["static1", "static2"],
                    description: NSLocalizedString("symptoms.visualSnow.description", comment: "")
                )

                SymptomCard(
                    title: NSLocalizedString("symptoms.palinopsia.title", comment: ""),
                    imageNames: ["AfterImage1", "afterimage2"],
                    description: NSLocalizedString("symptoms.palinopsia.description", comment: "")
                )

                SymptomCard(
                    title: NSLocalizedString("symptoms.doubleVision.title", comment: ""),
                    imageNames: ["double1", "double2"],
                    description: NSLocalizedString("symptoms.doubleVision.description", comment: "")
                )

                TextOnlySymptomCard(
                    title: NSLocalizedString("symptoms.photophobia.title", comment: ""),
                    description: NSLocalizedString("symptoms.photophobia.description", comment: "")
                )

                TextOnlySymptomCard(
                    title: NSLocalizedString("symptoms.nyctalopia.title", comment: ""),
                    description: NSLocalizedString("symptoms.nyctalopia.description", comment: "")
                )

                SymptomCard(
                    title: NSLocalizedString("symptoms.entopticPhenomena.title", comment: ""),
                    imageNames: ["Floaters1"],
                    description: NSLocalizedString("symptoms.entopticPhenomena.description", comment: "")
                )

                // Section 2: Non-Visual Symptoms
                sectionHeader(NSLocalizedString("symptoms.section.nonVisual", comment: ""))
                    .padding(.top, 8)

                NonVisualSymptomRow(
                    icon: "ear.trianglebadge.exclamationmark",
                    iconColor: .red,
                    title: NSLocalizedString("symptoms.tinnitus.title", comment: ""),
                    description: NSLocalizedString("symptoms.tinnitus.description", comment: "")
                )

                NonVisualSymptomRow(
                    icon: "brain.head.profile",
                    iconColor: .purple,
                    title: NSLocalizedString("symptoms.brainFog.title", comment: ""),
                    description: NSLocalizedString("symptoms.brainFog.description", comment: "")
                )

                NonVisualSymptomRow(
                    icon: "heart.text.clipboard",
                    iconColor: .pink,
                    title: NSLocalizedString("symptoms.anxietyDepression.title", comment: ""),
                    description: NSLocalizedString("symptoms.anxietyDepression.description", comment: "")
                )

                NonVisualSymptomRow(
                    icon: "moon.zzz",
                    iconColor: .indigo,
                    title: NSLocalizedString("symptoms.sleepDifficulties.title", comment: ""),
                    description: NSLocalizedString("symptoms.sleepDifficulties.description", comment: "")
                )

                NonVisualSymptomRow(
                    icon: "figure.fall",
                    iconColor: .orange,
                    title: NSLocalizedString("symptoms.dizziness.title", comment: ""),
                    description: NSLocalizedString("symptoms.dizziness.description", comment: "")
                )

                NonVisualSymptomRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .teal,
                    title: NSLocalizedString("symptoms.vertigo.title", comment: ""),
                    description: NSLocalizedString("symptoms.vertigo.description", comment: "")
                )

                NonVisualSymptomRow(
                    icon: "person.crop.circle.badge.questionmark",
                    iconColor: .gray,
                    title: NSLocalizedString("symptoms.dpdr.title", comment: ""),
                    description: NSLocalizedString("symptoms.dpdr.description", comment: "")
                )

                // Pinned disclaimer footer
                DisclaimerFooter()
                    .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 16)
        .navigationTitle("Symptoms")
    }

    // MARK: - Disclaimer Banner

    private var disclaimerBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(NSLocalizedString("symptoms.disclaimer", comment: ""))
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NSLocalizedString("symptoms.disclaimer", comment: ""))
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.bold())
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Symptom Card

private struct SymptomCard: View {
    let title: String
    let imageNames: [String]
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())

            HStack(spacing: 8) {
                ForEach(imageNames, id: \.self) { name in
                    imagePlaceholder(name: name)
                }
            }

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func imagePlaceholder(name: String) -> some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            placeholder
        }
        #else
        placeholder
        #endif
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.secondary.opacity(0.15))
            .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    Text(NSLocalizedString("symptoms.addImage", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
    }
}

// MARK: - Text-Only Symptom Card

private struct TextOnlySymptomCard: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Non-Visual Symptom Row

private struct NonVisualSymptomRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(iconColor, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
}
