//
//  HowItWorksView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/18/22.
//

import SwiftUI

struct HowItWorksView: View {
    private static let tutorialsURL = URL(string: "https://www.youtube.com/playlist?list=PLWXp2X5PBDOmFd1kqyYsPtYwdgXIfDZT3")!

    @Environment(StateManager.self) private var stateManager

    var body: some View {
        VStack(spacing: 0) {
            List(FAQItem.all, children: \.items) { item in
                Text(item.name)
                    .padding(.vertical, 10)
            }

            Link("View Tutorials", destination: Self.tutorialsURL)
                .buttonStyle(.pill)
                .disabled(!stateManager.isConnected)
                .padding()
        }
        .navigationTitle("How It Works")
    }
}

#Preview {
    NavigationStack {
        HowItWorksView()
    }
    .environment(StateManager.preview())
}
