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
                if (!stateManager.connected) {
                    Text("You are Offline")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(10)
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                
                if (stateManager.userFiles.count > 0) {
                    Section(header: Text("Your Lists")) {
                        ForEach(stateManager.userFiles, id: \.self) { file in
                            NavigationLink(destination: CategoryList(file: file)) {
                                HStack {
                                    Text(file.name)
                                    if (stateManager.isDeletingSheet == file) {
                                        Spacer()
                                        ProgressView()
                                    }
                                }
                            }
                                .disabled(!stateManager.connected && stateManager.activeFile != file)
                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                .swipeActions {
                                    if (UIApplication.shared.canOpenURL(stateManager.activeFileUrl())) {
                                        Button {
                                            stateManager.editFile(file: file)
                                        } label: {
                                            Label("Edit", systemImage: "square.and.pencil")
                                        }
                                        .disabled(!stateManager.connected)
                                        .tint(.blue)
                                    } else {
                                        Button {
                                            stateManager.viewFile(file: file)
                                        } label: {
                                            Label("View", systemImage: "eye.fill")
                                        }
                                        .disabled(!stateManager.connected)
                                        .tint(.yellow)
                                    }
                                    
                                    Button(role: .destructive) {
                                        isConfirming = true
                                        self.selectedFileToDelete = file
                                        print("foobar")
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                    .disabled(!stateManager.connected)

                                }
                        }
                    }
                }
                if (stateManager.defaultFiles.count > 0) {
                    Section(header: Text("Preloaded Lists")) {
                        ForEach(stateManager.defaultFiles, id: \.self) { file in
                            NavigationLink(destination: CategoryList(file: file)) {
                                Text(file.name)
                            }
                            .disabled(!stateManager.connected && stateManager.activeFile != file)
                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                .swipeActions {
                                    Button {
                                        stateManager.viewFile(file: file)
                                    } label: {
                                        Label("View", systemImage: "eye.fill")
                                    }
                                    .tint(.yellow)
                                    .disabled(!stateManager.connected)
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
                        Button(action: {
                            self.stateManager.showLoginActionSheet = true
                        }, label: {
                            Text("Login")
                        })
                        .disabled(!stateManager.connected)
                        .foregroundColor(
                            !stateManager.connected ? Color.gray : (colorScheme == .dark ? Color.white : Color.black)
                        )
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
                            .disabled(!stateManager.connected)
                            .foregroundColor(
                                !stateManager.connected ? Color.gray : (colorScheme == .dark ? Color.white : Color.black)
                            )
                        Button(action: {
                            self.stateManager.logOut()
                        }, label: {
                            Text("Log out")
                        })
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)

                    }
                }
                
                Section(header: Text("About")) {
                    NavigationLink(destination: HowItWorksView()) {
                        Text("How It Works")
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
            .navigationTitle("CyrusLyrics")
        }
        .sheet(isPresented: $showCreateActionSheet) {
            SheetView()
        }
        .sheet(isPresented: $stateManager.showLoginActionSheet) {
            SafariView(url: stateManager.authUrl())
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
                TextField("List Name", text: $sheetName)
                    .modifier(TextFieldClearButton(text: $sheetName))
                    .multilineTextAlignment(.leading)
                    .focused($sheetNameFieldIsFocused, equals: .sheetNameField)
                    .submitLabel(.go)
                    .onSubmit {
                        if (sheetName.isEmpty) {
                            return
                        }
                        
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
            .navigationBarTitle("Create List")
        }
    }
}

struct TextFieldClearButton: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack {
            content
            
            if !text.isEmpty {
                Button(
                    action: { self.text = "" },
                    label: {
                        Image(systemName: "delete.left")
                            .foregroundColor(Color.gray)
                    }
                )
            }
        }
    }
}

struct SetDataView_Previews: PreviewProvider {
    static var previews: some View {
        SetDataView()
    }
}
