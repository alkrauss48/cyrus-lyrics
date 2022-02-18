//
//  SetDataView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct SetDataView: View {
    @StateObject var stateManager = StateManager.Get()
    @State private var showCreateActionSheet = false
    
    var body: some View {
        NavigationView {
            List {
                if (stateManager.defaultFiles.count > 0) {
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
                }
                if (stateManager.userFiles.count > 0) {
                    Section(header: Text("Your Lists")) {
                        ForEach(stateManager.userFiles, id: \.self) { file in
                            Button(action: {
                                stateManager.setActiveFile(file: file, isUserFile: true)
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
                            })                    }
                    }
                }
                Section(header: Text("Actions")) {
                    if (!stateManager.isLoggedIn()) {
                        Link("Login", destination: stateManager.authUrl())
                    } else {
                        Button(action: {
                            self.showCreateActionSheet.toggle()
                        }, label: {
                            if (stateManager.isCreatingSheet) {
                                HStack {
                                    Text("Create Sheet")
                                    Spacer()
                                    ProgressView()
                                }
                            } else {
                                Text("Create Sheet")
                            }
                        })
                        Button(action: {
                            self.stateManager.logOut()
                        }, label: {
                            Text("Log out")
                        })
                    }
                }
           }
            .refreshable {
                stateManager.listDefaultSheets()
                stateManager.listUserSheets()
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
        .sheet(isPresented: $showCreateActionSheet) {
            SheetView()
        }
        
    }
}

struct SheetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var stateManager = StateManager.Get()
    @State var sheetName: String = "My CyrusLyrics Songs"
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Sheet Name", text: $sheetName)
                Section {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                    Button(action: {
                        stateManager.createSheetUrl(title: self.sheetName)
                        dismiss()
                    }) {
                        Text("Submit")
                    }
                }
            }
            .navigationBarTitle("Create Sheet")
        }
    }
}

struct SetDataView_Previews: PreviewProvider {
    static var previews: some View {
        SetDataView()
    }
}
