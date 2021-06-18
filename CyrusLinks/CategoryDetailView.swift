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
        NavigationView {
            List(category.subCategories, id: \.id) { subCategory in
                NavigationLink(destination: LinkDetailView()) {
                    Text(subCategory.name)
                }
            }
            .navigationTitle(category.name)
        }
    }
}

//struct CategoryDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryDetailView()
//    }
//}
