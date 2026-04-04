// DisclaimerFooter.swift
// Visual Snow Solace
//
// Reusable disclaimer footer displayed at the bottom of exercise and audio
// views. Reminds users this is not a medical device.

import SwiftUI

struct DisclaimerFooter: View {
    var body: some View {
        Text(NSLocalizedString("disclaimer.text", comment: "Disclaimer text shown at bottom of screens"))
            .font(.caption2)
            .italic()
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
            .accessibilityLabel(NSLocalizedString("disclaimer.accessibilityLabel", comment: "Accessibility label for disclaimer"))
    }
}
