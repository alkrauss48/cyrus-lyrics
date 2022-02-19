//
//  CategoryList.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/18/22.
//

import SwiftUI

struct HowItWorksView: View {
    let items: [Bookmark] = [.example1, .example2, .example3]
    @StateObject var stateManager = StateManager.Get()

    var body: some View {
        NavigationView {
            List(items, children: \.items) { row in
                Image(systemName: row.icon)
                Text(row.name)
            }
            .navigationTitle("How It Works")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        stateManager.toggleMenu()
                    }) {
                        Image(systemName: "line.horizontal.3")
                    }
                }
            }
        }
    }
}

struct HowItWorksView_Previews: PreviewProvider {
    static var previews: some View {
        HowItWorksView()
    }
}