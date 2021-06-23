//
//  CategoryDetailView.swift
//  CyrusLinks
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct SubCategoryDetailView: View {
    var subCategory: AppSubCategory

    var body: some View {
        List(subCategory.links.sorted { $0.name < $1.name }, id: \.id) { link in
            NavigationLink(destination: LinkDetailView(link: link, shuffleType: nil, shuffleId: nil)) {
                Text(link.name)
            }
        }
        .navigationTitle(subCategory.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {Text("")}
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: LinkDetailView(link: nil, shuffleType: "subCategory", shuffleId: subCategory.id)) {
                    Image(systemName: "shuffle")
                }
            }
        }
    }
}

//struct SubCategoryDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        SubCategoryDetailView()
//    }
//}
