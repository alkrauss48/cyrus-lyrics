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
    @State private var isConfirming = false
    @State private var selectedFileToDelete: APIFile?
    @Environment(\.colorScheme) var colorScheme

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
                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                .swipeActions {
                                    Button {
                                        stateManager.viewFile(file: file)
                                    } label: {
                                        Label("View", systemImage: "eye.fill")
                                    }
                                    .tint(.yellow)
                                }
                        }
                    }
                }
                if (stateManager.userFiles.count > 0) {
                    Section(header: Text("Your Lists")) {
                        ForEach(stateManager.userFiles, id: \.self) { file in
                            Button(action: {
                                stateManager.setActiveFile(file: file, isUserFile: true)
                            }, label: {
                                if (stateManager.isDeletingSheet == file) {
                                    HStack {
                                        Text(file.name)
                                        Spacer()
                                        ProgressView()
                                    }
                                } else if (stateManager.activeFile == file) {
                                    HStack {
                                        Text(file.name)
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                } else {
                                    Text(file.name)
                                }
                            })
                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                .swipeActions {
                                    if (UIApplication.shared.canOpenURL(stateManager.activeFileUrl())) {
                                        Button {
                                            stateManager.editFile(file: file)
                                        } label: {
                                            Label("Edit", systemImage: "square.and.pencil")
                                        }
                                        .tint(.blue)
                                    } else {
                                        Button {
                                            stateManager.viewFile(file: file)
                                        } label: {
                                            Label("View", systemImage: "eye.fill")
                                        }
                                        .tint(.yellow)
                                    }
                                    
                                    Button(role: .destructive) {
                                        isConfirming = true
                                        self.selectedFileToDelete = file
                                        print("foobar")
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                        }
                    }
                }
                Section(header: Text("Actions"), footer: HStack {
                    Text("Powered by ")
                    Image("google-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                }) {
                    if (!stateManager.isLoggedIn()) {
                        Link("Login", destination: stateManager.authUrl())
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    } else {
                        Button(action: {
                            self.showCreateActionSheet.toggle()
                        }, label: {
                            if (stateManager.isCreatingSheet) {
                                HStack {
                                    Text("Create List")
                                    Spacer()
                                    ProgressView()
                                }
                            } else {
                                Text("Create List")
                            }
                        })
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)

                        Button(action: {
                            self.stateManager.logOut()
                        }, label: {
                            Text("Log out")
                        })
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)

                    }
                }
           }
            .confirmationDialog(
                "Are you sure you want to delete this file?",
                isPresented: $isConfirming
            ) {
                Button(role: .destructive) {
                    if (selectedFileToDelete != nil) {
                        stateManager.deleteFile(file: selectedFileToDelete!)
                    }
                    
                    selectedFileToDelete = nil
                } label: {
                    Text("Send List to Trash")
                }
                
                Button("Cancel", role: .cancel) {
                    selectedFileToDelete = nil
                }
            }
            .refreshable {
                stateManager.listDefaultSheets()
                stateManager.listUserSheets()
            }
            .navigationTitle("Change List")
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
    @Environment(\.colorScheme) var colorScheme
    @StateObject var stateManager = StateManager.Get()
    @State var sheetName: String = "My CyrusLyrics Songs"
    @FocusState private var sheetNameFieldIsFocused: Field?

    private enum Field: Int, Hashable {
        case sheetNameField
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Sheet Name", text: $sheetName)
                    .focused($sheetNameFieldIsFocused, equals: .sheetNameField)
                    .submitLabel(.go)
                    .onSubmit {
                        stateManager.createSheetUrl(title: self.sheetName)
                        dismiss()
                    }
                Section {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                    .foregroundColor(Color.red)
                }
            }
            .onAppear {
                print("on appear")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {  /// Anything over 0.5 seems to work
                    sheetNameFieldIsFocused = .sheetNameField
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
