//
//  LinkDetailView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct LinkDetailView: View {
    @StateObject private var shuffleManager = ShuffleManager()
    @State var link: AppLink?
    let shuffleType: String?
    let shuffleId: UUID?
    
    var body: some View {
        VStack {
            if link != nil {
                if link!.lyrics.isEmpty {
                    SwiftUIWebView(url: URL(string: link!.url))
                } else {
                    LyricsView(lyrics: link!.lyrics)
                }
                
                if let url = URL(string: link!.spotifyUrl), UIApplication.shared.canOpenURL(url) {
                    HStack {
                        SpotifyButton(url: url)
                    }.padding()
                }
            }
        }
        .navigationBarTitle(link != nil ? link!.name : "", displayMode: .inline)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true

            if (link == nil) {
                link = shuffleManager.shuffleBy(type: shuffleType ?? "all", id: shuffleId)
            } else {
                shuffleManager.reset()
            }
        }
        .onDisappear() {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if (shuffleManager.shuffleData != nil) {
                    Button(action: {
                        if let nextLink = shuffleManager.next() {
                            link = nextLink
                        }
                    }) {
                        Image(systemName: "arrow.forward")
                    }
                }
            }
        }
    }
}

//struct LinkDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        LinkDetailView(shuffleType: nil, shuffleId: nil)
//    }
//}
