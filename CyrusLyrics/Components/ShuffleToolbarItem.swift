//
//  ShuffleToolbarItem.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/24/21.
//

import SwiftUI

struct ShuffleToolbarItem: ToolbarContent {
    let type: String?
    let id: UUID?
    var isHidden: Bool
    
    init(type: String?, id: UUID?, isHidden: Bool = false) {
        self.type = type
        self.id = id
        self.isHidden = isHidden
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if (!isHidden) {
                NavigationLink(destination: LinkDetailView(link: nil, shuffleType: type, shuffleId: id)) {
                    Image(systemName: "shuffle")
                }
            }
        }
    }
}
