//
//  CategoryDetailView.swift
//  CyrusLinks
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct CategoryDetailView: View {
    var category: AppCategory

    var body: some View {
        List(category.subCategories.sorted { $0.name < $1.name }, id: \.id) { subCategory in
            NavigationLink(destination: SubCategoryDetailView(subCategory: subCategory)) {
                Text(subCategory.name)
            }
        }
        .navigationTitle(category.name)
        .toolbar {
            ShuffleToolbarItem(type: "category", id: category.id)
        }
    }
}

//struct CategoryDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryDetailView()
//    }
//}
