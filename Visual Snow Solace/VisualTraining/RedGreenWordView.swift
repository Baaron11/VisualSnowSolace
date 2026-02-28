// RedGreenWordView.swift
// Visual Snow Solace
//
// Red/Green anaglyphic word training exercise. Displays the full Dolch
// sight word list in alternating red and green columns so that each eye
// sees a different set of words when viewed through red/green anaglyph
// lenses. Supports 2- or 4-column layouts, adjustable font size, and
// shuffling for varied practice sessions.

import SwiftUI

// MARK: - Font Size

enum RedGreenFontSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }

    var font: Font {
        switch self {
        case .small: return .callout
        case .medium: return .body
        case .large: return .title3
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .small: return .callout
        case .medium: return .body
        case .large: return .title3
        }
    }
}

// MARK: - Dolch Word List

private enum WordList {
    /// Complete Dolch sight word list (~220 service words plus 95 nouns).
    /// These are public-domain high-frequency words used in reading education.
    static let dolch: [String] = [
        // Pre-Primer (40 words)
        "a", "and", "away", "big", "blue", "can", "come", "down",
        "find", "for", "funny", "go", "help", "here", "I", "in",
        "is", "it", "jump", "little", "look", "make", "me", "my",
        "not", "one", "play", "red", "run", "said", "see", "the",
        "three", "to", "two", "up", "we", "where", "yellow", "you",

        // Primer (52 words)
        "all", "am", "are", "at", "ate", "be", "black", "brown",
        "but", "came", "did", "do", "eat", "four", "get", "good",
        "have", "he", "into", "like", "must", "new", "no", "now",
        "on", "our", "out", "please", "pretty", "ran", "ride", "saw",
        "say", "she", "so", "soon", "that", "there", "they", "this",
        "too", "under", "want", "was", "well", "went", "what", "white",
        "who", "will", "with", "yes",

        // First Grade (41 words)
        "after", "again", "an", "any", "as", "ask", "by", "could",
        "every", "fly", "from", "give", "going", "had", "has", "her",
        "him", "his", "how", "just", "know", "let", "live", "may",
        "of", "old", "once", "open", "over", "put", "round", "some",
        "stop", "take", "thank", "them", "then", "think", "walk", "were",
        "when",

        // Second Grade (46 words)
        "always", "around", "because", "been", "before", "best", "both", "buy",
        "call", "cold", "does", "don't", "fast", "first", "five", "found",
        "gave", "goes", "green", "its", "made", "many", "off", "or",
        "pull", "read", "right", "sing", "sit", "sleep", "tell", "their",
        "these", "those", "upon", "us", "use", "very", "wash", "which",
        "why", "wish", "work", "would", "write", "your",

        // Third Grade (41 words)
        "about", "better", "bring", "carry", "clean", "cut", "done", "draw",
        "drink", "eight", "fall", "far", "full", "got", "grow", "hold",
        "hot", "hurt", "if", "keep", "kind", "laugh", "light", "long",
        "much", "myself", "never", "only", "own", "pick", "seven", "shall",
        "show", "six", "small", "start", "ten", "today", "together", "try",
        "warm",

        // Dolch Nouns (95 words)
        "apple", "baby", "back", "ball", "bear", "bed", "bell", "bird",
        "birthday", "boat", "box", "boy", "bread", "brother", "cake", "cat",
        "chair", "chicken", "children", "Christmas", "coat", "corn", "cow", "day",
        "dog", "doll", "door", "duck", "egg", "eye", "farm", "farmer",
        "father", "feet", "fire", "fish", "floor", "flower", "game", "garden",
        "girl", "goodbye", "grass", "ground", "hand", "head", "hill", "home",
        "horse", "house", "kitty", "leg", "letter", "man", "men", "milk",
        "money", "morning", "mother", "name", "nest", "night", "paper", "party",
        "picture", "pig", "rabbit", "rain", "ring", "robin", "Santa Claus",
        "school", "seed", "sheep", "shoe", "sister", "snow", "song", "squirrel",
        "stick", "street", "sun", "table", "thing", "time", "top", "toy",
        "tree", "watch", "water", "way", "wind", "window", "wood"
    ]
}

// MARK: - View

struct RedGreenWordView: View {
    @State private var displayedWords: [String] = []
    @State private var columnCount: Int = 4
    @State private var fontSize: RedGreenFontSize = .medium
    @State private var instructionsExpanded: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Controls
                controlsBar

                // Instructions panel
                instructionsPanel

                // Word grid
                wordGrid

                DisclaimerFooter()
            }
            .padding(.vertical)
        }
        .navigationTitle("Red/Green Word Training")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayedWords = WordList.dolch.shuffled()
        }
    }

    // MARK: - Controls

    private var controlsBar: some View {
        HStack(spacing: 12) {
            Button {
                displayedWords = WordList.dolch.shuffled()
            } label: {
                Label("Shuffle", systemImage: "shuffle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Shuffle words")

            Picker("Columns", selection: $columnCount) {
                Text("2").tag(2)
                Text("4").tag(4)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            .accessibilityLabel("Column count")

            Picker("Size", selection: $fontSize) {
                ForEach(RedGreenFontSize.allCases) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Font size")
        }
        .padding(.horizontal)
    }

    // MARK: - Instructions

    private var instructionsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    instructionsExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Instructions")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: instructionsExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(instructionsExpanded ? "Collapse instructions" : "Expand instructions")

            if instructionsExpanded {
                Text("Use red/green anaglyphic glasses (red lens on left eye, green on right — or as directed). With the glasses on, the red words will be visible to one eye and the green words to the other. Read each word aloud as you scan down the columns. Shuffle to practice with a new word order.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Word Grid

    private var wordGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: columnCount
        )

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(displayedWords.enumerated()), id: \.offset) { index, word in
                let colIndex = index % columnCount
                let color: Color = colIndex % 2 == 0 ? .red : .green

                Text(word)
                    .font(.system(fontSize.textStyle, design: .default, weight: .bold))
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                    .accessibilityLabel(word)
            }
        }
        .padding(.horizontal)
    }
}
