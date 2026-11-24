//
//  SubCategoryDetailView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

/// The songs in a sub-category.
struct SubCategoryDetailView: View {
    @Environment(StateManager.self) private var stateManager
    let subCategory: AppSubCategory

    var body: some View {
        List(subCategory.links) { link in
            NavigationLink(link.name) {
                LinkDetailView(link: link)
            }
            // Offline, only songs with lyrics saved in the sheet work
            .disabled(!stateManager.isConnected && !link.hasSavedLyrics)
        }
        .navigationTitle(subCategory.name)
        .toolbar {
            ShuffleToolbarItem(scope: .subCategory(subCategory.id))
        }
    }
}

#Preview {
    NavigationStack {
        SubCategoryDetailView(subCategory: AppCategory.samples[0].subCategories[0])
    }
    .environment(StateManager.preview())
}
