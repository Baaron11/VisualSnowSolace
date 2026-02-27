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
        title: "Visual Snow Syndrome — NIH Rare Diseases",
        summary: "NIH's Genetic and Rare Diseases Information Center overview of Visual Snow Syndrome, covering symptoms, diagnosis, and current understanding.",
        url: URL(string: "https://rarediseases.info.nih.gov/diseases/12062/visual-snow-syndrome")!,
        date: "NIH GARD"
    ),
    ResearchItem(
        title: "VSS Patient Guide — Visual Snow Initiative",
        summary: "Comprehensive patient-facing guide from the Visual Snow Initiative covering symptom categories, management strategies, and how to talk to your doctor.",
        url: URL(string: "https://www.visualsnowinitiative.org/vss-patient-guide/")!,
        date: "Visual Snow Initiative"
    ),
    ResearchItem(
        title: "Visual Snow Syndrome: A Review — PubMed 2024",
        summary: "Peer-reviewed review article (PubMed PMID 38465699) covering the current clinical understanding of VSS, proposed mechanisms, and diagnostic criteria.",
        url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/38465699/")!,
        date: "PubMed 2024"
    ),
    ResearchItem(
        title: "VSS Clinical Research — PMC 2025",
        summary: "Full-text article via PubMed Central examining clinical characteristics and patient-reported outcomes in Visual Snow Syndrome.",
        url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC12429512/")!,
        date: "PMC 2025"
    ),
    ResearchItem(
        title: "Clinical Research — Eye on Vision Foundation",
        summary: "Published clinical research from the Eye on Vision Foundation's journal examining VSS symptom profiles and patient experience.",
        url: URL(string: "https://www.eyeonvision.org/uploads/1/3/8/3/138334683/vdr8-2_clinicalresearch_tann.pdf")!,
        date: "Eye on Vision Foundation"
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
