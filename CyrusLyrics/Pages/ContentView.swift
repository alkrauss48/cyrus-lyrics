//
//  ContentView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct ContentView: View {
    @StateObject var stateManager = StateManager.Get()

    var body: some View {
        ZStack {
            if(stateManager.rootView == "SET_DATA_VIEW") {
                SetDataView()
            } else if (stateManager.rootView == "HOW_IT_WORKS_VIEW") {
                HowItWorksView()
            } else {
                CategoryList()
            }
            
            
            MainMenu(width: 270,
                    isOpen: stateManager.menuOpen,
                    menuClose: stateManager.toggleMenu)
        }
    }
    

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
