//
//  LyricsView.swift
//  CyrusLinks
//
//  Created by Aaron Krauss on 6/24/21.
//

import SwiftUI

struct LyricsView: View {
    let lyrics: String
    
    var body: some View {
        ScrollView {
            Text(lyrics)
                .padding()
        }
    }
}

struct LyricsView_Previews: PreviewProvider {
    static var previews: some View {
        LyricsView(lyrics: "Fancy Lyrics")
    }
}
