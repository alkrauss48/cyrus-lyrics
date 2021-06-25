//
//  ContentView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dataManager.queryAppData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ShuffleToolbarItem(type: "all", id: nil)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
