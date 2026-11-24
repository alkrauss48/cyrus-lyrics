//
//  ShuffleToolbarItem.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/24/21.
//

import SwiftUI

struct ShuffleToolbarItem: ToolbarContent {
    let scope: ShuffleScope
    var isHidden = false

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !isHidden {
                NavigationLink {
                    LinkDetailView(shuffling: scope)
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
            }
        }
    }
}
