//
//  CategoryList.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

/// The categories in a list.
struct CategoryList: View {
    @Environment(StateManager.self) private var stateManager
    let file: APIFile

    var body: some View {
        VStack(spacing: 0) {
            List(stateManager.categories) { category in
                NavigationLink(category.name) {
                    CategoryDetailView(category: category)
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if stateManager.isLoadingFile {
                    ProgressView()
                } else if stateManager.categories.isEmpty {
                    ContentUnavailableView {
                        Label("Your List Is Empty", systemImage: "music.note.list")
                    } description: {
                        if canAddSongs {
                            Text("Tap Add Songs to add songs to your list.")
                        }
                    }
                }
            }
            .refreshable {
                await stateManager.refreshActiveFile()
            }

            if stateManager.isUserFile {
                Group {
                    if canAddSongs, let url = file.sheetsAppURL {
                        Link("Add Songs", destination: url)
                            .buttonStyle(.pill)
                            .disabled(!stateManager.isConnected)
                    } else {
                        Text("Download the Google Sheets app to add songs to your list.")
                    }
                }
                .padding()
            }
        }
        .navigationTitle(file.name)
        .toolbar {
            ShuffleToolbarItem(scope: .all, isHidden: stateManager.categories.isEmpty)
        }
        .onAppear {
            stateManager.open(file)
        }
    }

    private var canAddSongs: Bool {
        stateManager.isUserFile && GoogleSheetsApp.isInstalled
    }
}

#Preview {
    NavigationStack {
        CategoryList(file: .preview)
    }
    .environment(StateManager.preview())
}
