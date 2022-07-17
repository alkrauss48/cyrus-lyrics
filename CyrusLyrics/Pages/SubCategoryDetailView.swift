//
//  CategoryDetailView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct SubCategoryDetailView: View {
    @StateObject var stateManager = StateManager.Get()
    var subCategory: AppSubCategory

    var body: some View {
        List(subCategory.links.sorted { $0.name < $1.name }, id: \.id) { link in
            NavigationLink(destination: LinkDetailView(link: link, shuffleType: nil, shuffleId: nil)) {
                Text(link.name)
            }.disabled(!stateManager.connected && link.lyrics.isEmpty)
        }
        .navigationTitle(subCategory.name)
        .toolbar {
            ToolbarItemHack()
            ShuffleToolbarItem(type: "subCategory", id: subCategory.id)
        }
    }
}

//struct SubCategoryDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        SubCategoryDetailView()
//    }
//}
