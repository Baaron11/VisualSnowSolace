// RootView.swift
// Visual Snow Solace
//
// Navigation shell for the app. Provides a TabView with three tabs:
// Home, Quick Relief, and Log.

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }

            Tab("Quick Relief", systemImage: "bolt.heart.fill") {
                NavigationStack {
                    QuickReliefView()
                }
            }

            Tab("Log", systemImage: "list.clipboard") {
                NavigationStack {
                    LogView()
                }
            }
        }
    }
}
