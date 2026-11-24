//
//  PreviewData.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation

// Sample data for SwiftUI previews.

extension APIFile {
    static let preview = APIFile(id: "preview", name: "Demo Songs")
}

extension AppCategory {
    static let samples: [AppCategory] = [
        AppCategory(name: "Country", subCategories: [
            AppSubCategory(name: "Darius Rucker", links: [
                AppLink(
                    name: "Wagon Wheel",
                    url: SheetParser.defaultLyricsURL(song: "Wagon Wheel", artist: "Darius Rucker"),
                    lyrics: "Headed down south to the land of the pines\nI'm thumbin' my way into North Caroline",
                    spotifyUrl: "https://open.spotify.com/track/3xdjjKMcMOFgo1eQrfbogM"
                ),
            ]),
        ]),
        AppCategory(name: "Kids", subCategories: [
            AppSubCategory(name: "Traditional", links: [
                AppLink(
                    name: "Twinkle Twinkle Little Star",
                    url: SheetParser.defaultLyricsURL(song: "Twinkle Twinkle Little Star", artist: "Traditional"),
                    lyrics: "",
                    spotifyUrl: ""
                ),
            ]),
        ]),
    ]
}

extension StateManager {
    /// A state manager with sample data that doesn't touch the app's real
    /// saved data.
    static func preview() -> StateManager {
        let suiteName = "CyrusLyricsPreview"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)

        let store = LocalStore(defaults: defaults)
        store.set(true, for: .hasLaunched)
        store.save([APIFile.preview], for: .defaultFiles)
        store.save(APIFile.preview, for: .activeFile)
        store.save(AppCategory.samples, for: .categories)

        return StateManager(store: store, tokenStore: TokenStore(service: "com.cyruskrauss.cyruslyrics.preview"))
    }
}
