//
//  LinkDetailView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

/// A song's lyrics. When shuffling, a toolbar button moves to the next song.
struct LinkDetailView: View {
    @Environment(StateManager.self) private var stateManager
    @State private var link: AppLink?
    @State private var shuffleBag: ShuffleBag<AppLink>?
    private let shuffleScope: ShuffleScope?

    init(link: AppLink) {
        _link = State(initialValue: link)
        shuffleScope = nil
    }

    init(shuffling scope: ShuffleScope) {
        shuffleScope = scope
    }

    var body: some View {
        content
            .navigationTitle(link?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if shuffleBag != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Next Song", systemImage: "arrow.forward") {
                            link = shuffleBag?.next() ?? link
                        }
                    }
                }
            }
            .onAppear {
                // Keep the screen on while singing
                UIApplication.shared.isIdleTimerDisabled = true

                if let shuffleScope, shuffleBag == nil {
                    var bag = ShuffleBag(stateManager.categories.links(in: shuffleScope))
                    link = bag.next()
                    shuffleBag = bag
                }
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
    }

    @ViewBuilder
    private var content: some View {
        if let link {
            VStack(spacing: 0) {
                if link.hasSavedLyrics {
                    LyricsView(lyrics: link.lyrics)
                } else if !stateManager.isConnected {
                    ContentUnavailableView(
                        "You Are Offline",
                        systemImage: "wifi.slash",
                        description: Text("Add this song's lyrics to your Google Sheet to see them offline.")
                    )
                } else {
                    WebView(url: link.lyricsURL)
                }

                if let url = link.spotifyURL, UIApplication.shared.canOpenURL(url) {
                    Link("Open in Spotify", destination: url)
                        .buttonStyle(.pill(.spotify))
                        .padding()
                }
            }
        } else if shuffleBag?.isEmpty == true {
            ContentUnavailableView("No Songs to Shuffle", systemImage: "shuffle")
        } else {
            // Shuffle picks its first song in onAppear, which SwiftUI only
            // calls when there's a view on screen, so this can't be empty.
            Color.clear
        }
    }
}

#Preview("Lyrics") {
    NavigationStack {
        LinkDetailView(link: AppCategory.samples[0].subCategories[0].links[0])
    }
    .environment(StateManager.preview())
}

#Preview("Shuffle") {
    NavigationStack {
        LinkDetailView(shuffling: .all)
    }
    .environment(StateManager.preview())
}
