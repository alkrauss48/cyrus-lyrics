//
//  LyricsView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/24/21.
//

import SwiftUI

struct LyricsView: View {
    let lyrics: String

    var body: some View {
        ScrollView {
            Text(lyrics)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

#Preview {
    LyricsView(lyrics: "Fancy lyrics\nOn more than one line")
}
