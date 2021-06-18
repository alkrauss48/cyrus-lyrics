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
    var body: some View {
        NavigationView {
            List(linkCategoryList) { linkCategory in
                NavigationLink(destination: LinkDetailView()) {
                    Text(linkCategory.name)
                }
            }.navigationTitle("Categories")
        }.onAppear {
            loadAppData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
