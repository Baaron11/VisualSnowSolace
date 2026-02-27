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
                sectionHeader("Visual Symptoms")

                SymptomCard(
                    title: "Visual Snow",
                    imageNames: ["static1", "static2"],
                    description: "Visual snow appears as a persistent flickering static overlaid on your entire visual field — similar to the noise on an old television. It is present in all lighting conditions and does not go away when you close your eyes. For some, it appears as fine colored dots; for others, as a dense black-and-white grain."
                )

                SymptomCard(
                    title: "Palinopsia (Afterimages)",
                    imageNames: ["afterimage1", "afterimage2"],
                    description: "Palinopsia causes visual images to persist or recur after the original stimulus is gone. This includes trailing afterimages that follow moving objects, and static afterimages that linger after looking at a bright or high-contrast object. It can range from mild (brief trailing) to severe (prolonged ghost images)."
                )

                SymptomCard(
                    title: "Double Vision (Diplopia)",
                    imageNames: ["double1", "double2"],
                    description: "Diplopia causes a single object to appear as two overlapping or separated images. In VSS this may occur as a persistent or intermittent symptom, and can affect one eye (monocular) or both eyes together (binocular). It can make reading, screen use, and driving significantly more difficult."
                )

                TextOnlySymptomCard(
                    title: "Photophobia (Light Sensitivity)",
                    description: "Photophobia is an extreme sensitivity or intolerance to light. Ordinary indoor lighting, screens, or sunlight may feel painful or overwhelming. Bright lights can trigger or worsen other VSS symptoms. Many people with VSS find fluorescent and LED lighting particularly difficult."
                )

                TextOnlySymptomCard(
                    title: "Nyctalopia (Night Blindness / Poor Night Vision)",
                    description: "Nyctalopia in VSS refers to difficulty adapting to low-light environments. The visual snow effect often intensifies significantly in darkness, and contrast sensitivity is reduced. Night driving, dim restaurants, and dark rooms can be especially challenging."
                )

                SymptomCard(
                    title: "Entoptic Phenomena (Floaters)",
                    imageNames: ["floaters1", "floaters2"],
                    description: "Entoptic phenomena are visual effects that originate within the eye itself. In VSS this commonly includes floaters (moving shadows or threads), blue field entoptic phenomenon (tiny bright dots darting along the visual field in bright light), and self-light of the eye (patterns seen in complete darkness)."
                )

                // Section 2: Non-Visual Symptoms
                sectionHeader("Non-Visual Symptoms")
                    .padding(.top, 8)

                NonVisualSymptomRow(
                    icon: "ear.trianglebadge.exclamationmark",
                    iconColor: .red,
                    title: "Tinnitus",
                    description: "A persistent ringing, buzzing, hissing, or humming sound in one or both ears with no external source. Tinnitus is reported in a significant portion of people with VSS and can range from a minor background noise to a constant, distressing sound."
                )

                NonVisualSymptomRow(
                    icon: "brain.head.profile",
                    iconColor: .purple,
                    title: "Brain Fog",
                    description: "Difficulty concentrating, mental fatigue, slow processing, and trouble finding words. Brain fog in VSS can make work, reading, and conversation significantly harder, and often worsens with fatigue or overstimulation."
                )

                NonVisualSymptomRow(
                    icon: "heart.text.clipboard",
                    iconColor: .pink,
                    title: "Anxiety, Depression & Irritability",
                    description: "Living with persistent visual and sensory disturbances can lead to significant emotional strain. Anxiety, depression, and heightened irritability are commonly reported alongside VSS, and addressing mental health is an important part of overall management."
                )

                NonVisualSymptomRow(
                    icon: "moon.zzz",
                    iconColor: .indigo,
                    title: "Sleep Difficulties",
                    description: "Trouble falling asleep, staying asleep, or feeling rested. Visual snow and related symptoms can be more noticeable in the dark and quiet of night, making it harder to wind down. Some people also report vivid dreams or hypnagogic imagery."
                )

                NonVisualSymptomRow(
                    icon: "figure.fall",
                    iconColor: .orange,
                    title: "Dizziness",
                    description: "A sense of lightheadedness, unsteadiness, or feeling off-balance. Dizziness in VSS may be triggered by busy visual environments, screens, or physical movement, and can contribute to difficulty with everyday tasks."
                )

                NonVisualSymptomRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .teal,
                    title: "Vertigo",
                    description: "A spinning or rotational sensation, as if the room is moving. Vertigo differs from general dizziness and can be episodic or persistent. It may accompany or overlap with migraine, which is commonly associated with VSS."
                )

                NonVisualSymptomRow(
                    icon: "person.crop.circle.badge.questionmark",
                    iconColor: .gray,
                    title: "Depersonalization-Derealization (DPDR)",
                    description: "A feeling of being detached from your own thoughts, body, or surroundings, or of the world seeming unreal, dreamlike, or far away. DPDR is reported by many with VSS and can be one of the most distressing non-visual symptoms."
                )

                // Pinned disclaimer footer
                DisclaimerFooter()
                    .padding(.bottom, 8)
            }
            .padding()
        }
        .navigationTitle("Symptoms")
    }

    // MARK: - Disclaimer Banner

    private var disclaimerBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("For educational purposes only. Not a diagnostic tool. Consult your clinician.")
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Disclaimer: For educational purposes only. Not a diagnostic tool. Consult your clinician.")
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
            .frame(height: 160)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func imagePlaceholder(name: String) -> some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: 160)
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
            .frame(maxWidth: .infinity, maxHeight: 160)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    Text("Add image")
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
        .padding()
        .background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
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
