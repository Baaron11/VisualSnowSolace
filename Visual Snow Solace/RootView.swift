// RootView.swift
// Visual Snow Solace
//
// Navigation shell for the app. Provides a TabView with three tabs:
// Home, Quick Relief, and Log.

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab(NSLocalizedString("root.tab.home", comment: "Home tab label"), systemImage: "house.fill") {
                HomeView()
            }

            Tab(NSLocalizedString("root.tab.quickRelief", comment: "Quick Relief tab label"), systemImage: "bolt.heart.fill") {
                NavigationStack {
                    QuickReliefView()
                }
            }

            Tab(NSLocalizedString("root.tab.log", comment: "Log tab label"), systemImage: "list.clipboard") {
                NavigationStack {
                    LogView()
                }
            }
        }
    }
}
