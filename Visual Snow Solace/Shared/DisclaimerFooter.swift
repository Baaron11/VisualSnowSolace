// DisclaimerFooter.swift
// Visual Snow Solace
//
// Reusable disclaimer footer displayed at the bottom of exercise and audio
// views. Reminds users this is not a medical device.

import SwiftUI

struct DisclaimerFooter: View {
    var body: some View {
        Text("Not a medical device. For informational use only. Consult your clinician.")
            .font(.caption2)
            .italic()
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
            .accessibilityLabel("Disclaimer: Not a medical device. For informational use only. Consult your clinician.")
    }
}
