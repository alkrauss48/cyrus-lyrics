//
//  ShuffleManager.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/19/21.
//

import Foundation

class ShuffleManager: ObservableObject {
    var shuffleData: ShuffleData?
    var allCategories: [AppCategory] = []
    
    func reset() {
        self.shuffleData = nil
    }
    
    func next() -> AppLink? {
        guard var data = self.shuffleData else {
            return nil
        }

        if (data.links.isEmpty) {
            data.links = links(for: data)
        }

        guard let selectedIndex = data.links.indices.randomElement() else {
            self.shuffleData = data
            return nil
        }

        let selectedLink = data.links.remove(at: selectedIndex)
        self.shuffleData = data

        return selectedLink
    }
    
    private func links(for data: ShuffleData) -> [AppLink] {
        if (data.type == "category") {
            return allCategories
                .filter({ $0.id == data.id })
                .flatMap({ $0.subCategories })
                .flatMap({ $0.links })
        } else if (data.type == "subCategory") {
            return allCategories
                .flatMap({ $0.subCategories })
                .filter({ $0.id == data.id })
                .flatMap({ $0.links })
        }

        return allCategories
            .flatMap({ $0.subCategories })
            .flatMap({ $0.links })
    }
    
    func shuffleBy(type: String = "all", id: UUID? = nil) -> AppLink? {
        if allCategories.isEmpty {
            allCategories = StateManager.Get().categories
        }
        
        // Start a fresh shuffle pool when the shuffle scope changes
        if shuffleData == nil || shuffleData?.type != type || shuffleData?.id != id {
            self.shuffleData = ShuffleData(type: type, id: id, links: [])
        }
        
        return next()
    }
}
