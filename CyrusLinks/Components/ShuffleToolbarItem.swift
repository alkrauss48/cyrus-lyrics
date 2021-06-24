//
//  ShuffleToolbarItem.swift
//  CyrusLinks
//
//  Created by Aaron Krauss on 6/24/21.
//

import SwiftUI

struct ShuffleToolbarItem: ToolbarContent {
    let type: String?
    let id: UUID?
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: LinkDetailView(link: nil, shuffleType: type, shuffleId: id)) {
                Image(systemName: "shuffle")
            }
        }
    }
}
