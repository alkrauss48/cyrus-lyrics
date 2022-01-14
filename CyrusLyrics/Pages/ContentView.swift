//
//  ContentView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct ContentView: View {
    @StateObject var dataManager = DataManager()
    @State var menuOpen: Bool = false
    
    var body: some View {
        ZStack {
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
                            self.openMenu()
                        }) {
                            Image(systemName: "line.horizontal.3")
                        }
                    }
                    ShuffleToolbarItem(type: "all", id: nil)
                }
            }
            
            MainMenu(width: 270,
                    isOpen: self.menuOpen,
                    menuClose: self.openMenu)
        }
    }
    
    func openMenu() {
        self.menuOpen.toggle()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
