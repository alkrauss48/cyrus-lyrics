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
    
    func getListFooterText() -> String {
        return stateManager.activeFile != nil ? "List: " + stateManager.activeFile!.name : ""
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(footer: Text(getListFooterText())) {
                        if (stateManager.categories.isEmpty) {
                            if (stateManager.activeFile != nil && UIApplication.shared.canOpenURL(stateManager.activeFileUrl())) {
                                Text("Your list is empty. Click below to add songs.")
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
                                    .background(Color("Primary"))
                                    .cornerRadius(40)
                            }
                        }.padding()
                    } else {
                        HStack {
                            Text("Download the Google Sheets app to add songs to your list.")
                        }.padding()
                    }
                }

            }
            .refreshable {
                stateManager.refreshList()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        stateManager.toggleMenu()
                    }) {
                        Image(systemName: "line.horizontal.3")
                    }
                }
                ShuffleToolbarItem(type: "all", id: nil, isHidden: stateManager.categories.isEmpty)
            }
        }
    }
}

struct CategoryList_Previews: PreviewProvider {
    static var previews: some View {
        CategoryList()
    }
}
