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
            
            SideMenu(width: 270,
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

struct MenuContent: View {
    var body: some View {
        List {
            Text("My Profile").onTapGesture {
                print("My Profile")
            }
            Text("Posts").onTapGesture {
                print("Posts")
            }
            Text("Logout").onTapGesture {
                print("Logout")
            }
        }
    }
}

struct SideMenu: View {
    let width: CGFloat
    let isOpen: Bool
    let menuClose: () -> Void
    
    var body: some View {
        ZStack {
            GeometryReader { _ in
                EmptyView()
            }
            .background(Color.gray.opacity(0.3))
            .opacity(self.isOpen ? 1.0 : 0.0)
            .animation(Animation.easeIn.delay(0.25))
            .onTapGesture {
                self.menuClose()
            }
            
            HStack {
                MenuContent()
                    .frame(width: self.width)
                    .background(Color.white)
                    .offset(x: self.isOpen ? 0 : -self.width)
                    .animation(.default)
                
                Spacer()
            }
        }
    }
}
