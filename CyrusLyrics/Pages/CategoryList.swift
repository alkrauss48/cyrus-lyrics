//
//  CategoryList.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct CategoryList: View {
    @Environment(\.openURL) var openURL
    @StateObject var stateManager = StateManager.Get()
    let file: APIFile
    
    var body: some View {
            VStack {
                if (stateManager.isLoadingFile) {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    List {
                        Section() {
                            if (stateManager.categories.isEmpty) {
                                if (stateManager.activeFile != nil && UIApplication.shared.canOpenURL(stateManager.activeFileUrl())) {
                                    Text("Your list is empty. Click the button below to add songs.")
                                        .padding([.bottom, .top], 10)
                                } else {
                                    Text("Your list is empty.")
                                        .padding([.bottom, .top], 10)
                                }
                            }
                            
                            ForEach(stateManager.categories, id: \.id) { category in
                                NavigationLink(destination: CategoryDetailView(category: category)) {
                                    Text(category.name)
                                }
                            }
                        }
                    }.listStyle(InsetGroupedListStyle())
                }
                
                if (stateManager.isUserFile()) {
                    if (UIApplication.shared.canOpenURL(stateManager.activeFileUrl())) {
                        HStack {
                            Button(action: {
                                openURL(stateManager.activeFileUrl())
                            }) {
                                Text("Add Songs")
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(!stateManager.connected ? Color.gray : Color("Primary"))
                                    .cornerRadius(40)
                            }
                        }
                        .padding()
                        .disabled(!stateManager.connected)
                    } else {
                        HStack {
                            Text("Download the Google Sheets app to add songs to your list.")
                        }.padding()
                    }
                }
            }
            .onAppear() {
                stateManager.setActiveFile(file: file)
            }
            .refreshable {
                stateManager.refreshList()
            }
            .navigationTitle(file.name)
            .toolbar {
                ToolbarItemHack()
                ShuffleToolbarItem(type: "all", id: nil, isHidden: stateManager.categories.isEmpty)
            }
    }
}

//struct CategoryList_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryList()
//    }
//}
