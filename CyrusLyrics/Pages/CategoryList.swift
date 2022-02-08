//
//  CategoryList.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct CategoryList: View {
    @StateObject var dataManager = DataManager()
    @StateObject var stateManager = StateManager.Get()

    var body: some View {
        NavigationView {
            List(dataManager.categories, id: \.id) { category in
                NavigationLink(destination: CategoryDetailView(category: category)) {
                    Text(category.name)
                }
            }.refreshable {
                dataManager.queryAppData()
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
