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
    
    func loadAppData(data: Data) {
        let existingCategories = try? PropertyListDecoder().decode(Array<AppCategory>.self, from: data)
        
        self.allCategories = existingCategories!
    }
    
    func reset() {
        self.shuffleData = nil
    }
    
    func next() -> AppLink {
        if (self.shuffleData!.links.isEmpty) {
            prepareShuffleData()
        }
        
        let selectedLink = self.shuffleData!.links.randomElement()!
        let selectedIndex = self.shuffleData!.links.firstIndex(where: { $0.id == selectedLink.id })!
        self.shuffleData!.links.remove(at: selectedIndex)
        
        return selectedLink
    }
    
    func prepareShuffleData() {
        var links: [AppLink]
        
        if (self.shuffleData!.type == "category") {
            links = allCategories
                .filter({ $0.id == self.shuffleData!.id! })
                .flatMap({ $0.subCategories })
                .flatMap({ $0.links })
        } else if (self.shuffleData!.type == "subCategory") {
            links = allCategories
                .flatMap({ $0.subCategories })
                .filter({ $0.id == self.shuffleData!.id! })
                .flatMap({ $0.links })
        } else {
            links = allCategories
                .flatMap({ $0.subCategories })
                .flatMap({ $0.links })
        }
        
        self.shuffleData!.links = links
    }
    
    func shuffleBy(type: String = "all", id: UUID? = nil) -> AppLink {
        if allCategories.isEmpty, let data = UserDefaults.standard.value(forKey:"categories") as? Data {
            loadAppData(data: data)
        }
        
        if shuffleData == nil || (shuffleData?.type != type || shuffleData?.id == id) {
            self.shuffleData = ShuffleData(type: type, id: id, links: [])
        }
        
        if (self.shuffleData!.links.isEmpty) {
            prepareShuffleData()
        }
        
        return next()
    }
}
