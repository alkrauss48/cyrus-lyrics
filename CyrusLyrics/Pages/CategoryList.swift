//
//  CategoryList.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct CategoryList: View {
    @StateObject var stateManager = StateManager.Get()

    var body: some View {
        NavigationView {
            VStack {
                if (stateManager.activeFile != nil && stateManager.categories.isEmpty) {
                    List {
                        Text("No categories to show. Go log in to your Google Docs account and add some songs to the '" + stateManager.activeFile!.name + "' Google Sheet document!" )
                    }
                } else {
                    List(stateManager.categories, id: \.id) { category in
                        NavigationLink(destination: CategoryDetailView(category: category)) {
                            Text(category.name)
                        }
                    }
                }
            }
            .refreshable {
                if (!stateManager.categories.isEmpty) {
                    stateManager.refreshList()
                }
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
