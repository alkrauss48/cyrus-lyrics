//
//  CategoryDetailView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

/// The sub-categories in a category.
struct CategoryDetailView: View {
    let category: AppCategory

    var body: some View {
        List(category.subCategories) { subCategory in
            NavigationLink(subCategory.name) {
                SubCategoryDetailView(subCategory: subCategory)
            }
        }
        .navigationTitle(category.name)
        .toolbar {
            ShuffleToolbarItem(scope: .category(category.id))
        }
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(category: AppCategory.samples[0])
    }
    .environment(StateManager.preview())
}
