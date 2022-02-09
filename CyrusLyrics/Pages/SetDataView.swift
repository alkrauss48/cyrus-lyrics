//
//  SetDataView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct SetDataView: View {
    @State private var selection: String?
    @StateObject var stateManager = StateManager.Get()
    
    let defaultSheets = [
        "Demo Songs",
        "Cyrus' Dad's Songs",
    ]
    
    var body: some View {
        NavigationView {
            List(selection: $selection) {
                Section(header: Text("Preloaded Lists")) {
                    ForEach(defaultSheets, id: \.self) { sheet in
                        Text(sheet)
                    }
                }
                Section(header: Text("Your Lists")) {
                    Link("Login", destination: URL(string: "https://api.cyruskrauss.com/oauth/google")!)
                }
           }
            .navigationTitle("Set Data")
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
