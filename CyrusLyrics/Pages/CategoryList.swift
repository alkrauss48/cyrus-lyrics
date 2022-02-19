//
//  CategoryList.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct CategoryList: View {
    @Environment(\.openURL) var openURL
    @StateObject var stateManager = StateManager.Get()

    var body: some View {
        NavigationView {
            VStack {
                List {
                    if (stateManager.activeFile != nil && stateManager.categories.isEmpty) {
                        Text("No categories to show." )
                    } else {
                        ForEach(stateManager.categories, id: \.id) { category in
                            NavigationLink(destination: CategoryDetailView(category: category)) {
                                Text(category.name)
                            }
                        }
                    }
                    if (stateManager.isUserFile()) {
                        Button(action: {
                            openURL(stateManager.activeFileUrl())
                        }) {
                            Text("Add Songs")
                                .fontWeight(.semibold)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color("Primary"))
                                .cornerRadius(40)
                        }
                    }
                }
            }
            .refreshable {
                stateManager.refreshList()
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
                ShuffleToolbarItem(type: "all", id: nil, isHidden: stateManager.categories.isEmpty)
            }
        }
    }
}

struct CategoryList_Previews: PreviewProvider {
    static var previews: some View {
        CategoryList()
    }
}
