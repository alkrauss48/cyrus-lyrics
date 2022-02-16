//
//  SetDataView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct SetDataView: View {
    @StateObject var stateManager = StateManager.Get()
    
    let defaultSheets = [
        "Demo Songs",
        "Cyrus' Dad's Songs",
    ]
    
    var body: some View {
        NavigationView {
            List() {
                Section(header: Text("Preloaded Lists")) {
                    ForEach(stateManager.defaultFiles, id: \.self) { file in
                        Button(action: {
                            stateManager.setActiveFile(file: file)
                        }, label: {
                            if (stateManager.activeFile == file) {
                                HStack {
                                    Text(file.name)
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            } else {
                                Text(file.name)
                            }
                        })
                    }
                }
                Section(header: Text("Your Lists")) {
                    if (!stateManager.isLoggedIn()) {
                        Link("Login", destination: stateManager.authUrl())
                    } else {
                        Button(action: {
                            stateManager.listUserSheets()
                        }, label: {
                            Text("Create Sheet")
                        })
                    }
                    ForEach(stateManager.userFiles, id: \.self) { file in
                        Text(file.name)
                    }
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
