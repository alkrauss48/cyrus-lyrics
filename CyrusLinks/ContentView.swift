//
//  ContentView.swift
//  CyrusLinks
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct LinkCategory: Identifiable {
    let id = UUID()
    var name: String
}

private let linkCategoryList: [LinkCategory] = [
    LinkCategory(name: "Foo"),
    LinkCategory(name: "Bar"),
]

struct ContentView: View {
    @StateObject var dataManager = DataManager()

    var body: some View {
        NavigationView {
            List(dataManager.categories, id: \.id) { category in
                NavigationLink(destination: CategoryDetailView(category: category)) {
                    Text(category.name)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LinkDetailView(link: nil, shuffleType: "all", shuffleId: nil)) {
                        Image(systemName: "shuffle")
                    }
                    Button(action: {
                        dataManager.queryAppData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
