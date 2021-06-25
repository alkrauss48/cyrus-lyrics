//
//  LinkDetailView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct LinkDetailView: View {
    let shuffleManager = ShuffleManager()
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
            }
        }
        .navigationTitle(link != nil ? link!.name : "")
        .onAppear {
            if (link == nil) {
                link = shuffleManager.shuffleBy(type: shuffleType!, id: shuffleId)
            } else {
                shuffleManager.reset()
            }
        }
        .toolbar {
            ToolbarItemHack()
            ToolbarItem(placement: .navigationBarTrailing) {
                if (shuffleManager.shuffleData != nil) {
                    Button(action: {
                        link = shuffleManager.next()
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
//        LinkDetailView()
//    }
//}
