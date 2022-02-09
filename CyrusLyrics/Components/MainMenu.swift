//
//  MainMenu.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 1/14/22.
//

import SwiftUI

struct MainMenu: View {
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
            .animation(Animation.easeInOut(duration: 0.25), value: isOpen)
            .onTapGesture {
                self.menuClose()
            }
            
            HStack {
                MenuContent()
                    .frame(width: self.width)
                    .background(Color.white)
                    .offset(x: self.isOpen ? 0 : -self.width)
                    .animation(Animation.easeInOut(duration: 0.25), value: isOpen)

                Spacer()
            }
        }
    }
}

//struct MainMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        MainMenu(width: 270,
//                isOpen: true,
//                 menuClose: self.openMenu)    }
//}

struct MenuContent: View {
    @StateObject var stateManager = StateManager.Get()

    var body: some View {
        List {
            Button(action: {
                stateManager.rootView = "CATEGORY_LIST_VIEW"
                stateManager.toggleMenu()
            }, label: {
                Text("Home")
            })
            Button(action: {
                stateManager.rootView = "SET_DATA_VIEW"
                stateManager.toggleMenu()
            }, label: {
                Text("Set Data")
            })
            Section(header: Text("About")) {
                Text("How it Works").onTapGesture {
                    print("How it Works")
                }
                Text("Who is Cyrus?").onTapGesture {
                    print("Who is Cyrus?")
                }
            }
        }
    }
}
