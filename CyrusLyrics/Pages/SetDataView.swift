//
//  SetDataView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct SetDataView: View {
    @StateObject var stateManager = StateManager.Get()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Preloaded Data")) {
                    Text("Demo Songs").onTapGesture {
                        print("Home")
                    }
                    Text("Cyrus' Dad's Songs").onTapGesture {
                        print("Home")
                    }
                }

            }.navigationTitle("Set Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        stateManager.toggleMenu()
                    }) {
                        Image(systemName: "line.horizontal.3")
                    }
                }
            }
        }
    }
}

struct SetDataView_Previews: PreviewProvider {
    static var previews: some View {
        SetDataView()
    }
}
