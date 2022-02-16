//
//  CategoryList.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct CategoryList: View {
    @StateObject var stateManager = StateManager.Get()
    // @StateObject var foo = DataManager()

    var body: some View {
        NavigationView {
            List(stateManager.categories, id: \.id) { category in
                NavigationLink(destination: CategoryDetailView(category: category)) {
                    Text(category.name)
                }
            }.refreshable {
                stateManager.queryAppData()
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        stateManager.toggleMenu()
                    }) {
                        Image(systemName: "line.horizontal.3")
                    }
                }
                ShuffleToolbarItem(type: "all", id: nil)
            }
        }
    }
}

struct CategoryList_Previews: PreviewProvider {
    static var previews: some View {
        CategoryList()
    }
}
