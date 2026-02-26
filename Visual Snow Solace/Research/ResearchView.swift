// ResearchView.swift
// Visual Snow Solace
//
// Curated list of published Visual Snow Syndrome research papers. Tapping
// an item opens the paper in an in-app Safari view via SFSafariViewController.

import SwiftUI

#if canImport(UIKit)
import SafariServices
#endif

// MARK: - Data Model

struct ResearchItem: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let url: URL
    let date: String   // e.g. "2020"
}

// MARK: - Seed Data

private let researchItems: [ResearchItem] = [
    ResearchItem(
        title: "Visual Snow Syndrome: A Clinical and Phenotypological Description of 1,100 Cases",
        summary: "Large-scale survey characterising the clinical spectrum of VSS including comorbid symptoms such as palinopsia, photophobia, and tinnitus.",
        url: URL(string: "https://doi.org/10.1212/WNL.0000000000200983")!, // VERIFY URL
        date: "2022"
    ),
    ResearchItem(
        title: "Visual Snow Syndrome: Pathophysiology and Treatment",
        summary: "Comprehensive review of proposed pathophysiological mechanisms including thalamocortical dysrhythmia and potential therapeutic approaches.",
        url: URL(string: "https://doi.org/10.1007/s11916-020-00847-x")!, // VERIFY URL
        date: "2020"
    ),
    ResearchItem(
        title: "Prevalence of Visual Snow Syndrome in the UK",
        summary: "Population-based study estimating VSS prevalence at approximately 3.7 % using validated diagnostic criteria.",
        url: URL(string: "https://doi.org/10.1111/ene.15353")!, // VERIFY URL
        date: "2022"
    ),
    ResearchItem(
        title: "Brain Structure in Visual Snow Syndrome: A Multi-Modal MRI Study",
        summary: "Neuroimaging study revealing increased grey-matter volume in the lingual gyrus and cerebellum in VSS patients compared to controls.",
        url: URL(string: "https://doi.org/10.1002/ana.25955")!, // VERIFY URL
        date: "2020"
    ),
    ResearchItem(
        title: "Visual Snow Syndrome After Repetitive Transcranial Magnetic Stimulation",
        summary: "Case series exploring rTMS as a potential treatment, targeting hyperexcitability in visual cortex areas.",
        url: URL(string: "https://doi.org/10.1177/0333102419888808")!, // VERIFY URL
        date: "2020"
    ),
    ResearchItem(
        title: "The Visual Snow Initiative: New Developments in Understanding Visual Snow Syndrome",
        summary: "Overview of research milestones including functional PET findings showing lingual gyrus hypermetabolism as a potential biomarker.",
        url: URL(string: "https://doi.org/10.1186/s10194-021-01276-2")!, // VERIFY URL
        date: "2021"
    ),
    ResearchItem(
        title: "Colour Vision in Visual Snow Syndrome",
        summary: "Psychophysical study demonstrating subtle colour-discrimination deficits suggesting involvement of early visual processing pathways.",
        url: URL(string: "https://doi.org/10.1136/bjophthalmol-2021-319681")!, // VERIFY URL
        date: "2022"
    ),
]

// MARK: - Safari Representable

#if canImport(UIKit)
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

// MARK: - Research View

struct ResearchView: View {
    @State private var selectedItem: ResearchItem?

    var body: some View {
        List(researchItems) { item in
            Button {
                selectedItem = item
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Text(item.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    Text(item.date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(item.title), \(item.date)")
            .accessibilityHint("Opens research paper in browser")
        }
        .navigationTitle("Research")
        .sheet(item: $selectedItem) { item in
            #if canImport(UIKit)
            SafariView(url: item.url)
                .ignoresSafeArea()
            #else
            Text("Open \(item.url.absoluteString) in your browser.")
                .padding()
            #endif
        }
    }
}
