//
//  Library.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import Foundation

// These types are cached in UserDefaults as property lists, so the stored
// property names are part of the on-disk format. Don't rename them without
// migrating the cached data.

/// A song. It links to its lyrics, which are either a web page or lyrics
/// typed directly into the sheet.
struct AppLink: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    var name: String
    var url: String
    var lyrics: String
    var spotifyUrl: String

    var lyricsURL: URL? {
        URL(string: url)
    }

    var spotifyURL: URL? {
        spotifyUrl.isEmpty ? nil : URL(string: spotifyUrl)
    }

    /// Whether the lyrics are stored in the sheet itself, which makes them
    /// available offline.
    var hasSavedLyrics: Bool {
        !lyrics.isEmpty
    }
}

/// A second-level grouping of songs, usually an artist.
struct AppSubCategory: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    var name: String
    var links: [AppLink]
}

/// A top-level grouping of songs, usually a genre.
struct AppCategory: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    var name: String
    var subCategories: [AppSubCategory]
}

/// The set of songs that shuffle picks from.
enum ShuffleScope: Hashable, Sendable {
    case all
    case category(AppCategory.ID)
    case subCategory(AppSubCategory.ID)
}

extension Array where Element == AppCategory {
    /// Every song within `scope`.
    func links(in scope: ShuffleScope) -> [AppLink] {
        switch scope {
        case .all:
            return flatMap(\.subCategories).flatMap(\.links)
        case .category(let id):
            return filter { $0.id == id }.flatMap(\.subCategories).flatMap(\.links)
        case .subCategory(let id):
            return flatMap(\.subCategories).filter { $0.id == id }.flatMap(\.links)
        }
    }

    /// Sorts categories, sub-categories, and songs by name, the way the
    /// Finder sorts file names.
    func sortedByName() -> [AppCategory] {
        map { category in
            var category = category
            category.subCategories = category.subCategories
                .map { subCategory in
                    var subCategory = subCategory
                    subCategory.links = subCategory.links.sorted(byName: \.name)
                    return subCategory
                }
                .sorted(byName: \.name)
            return category
        }
        .sorted(byName: \.name)
    }
}

extension Sequence {
    func sorted(byName name: (Element) -> String) -> [Element] {
        sorted { name($0).localizedStandardCompare(name($1)) == .orderedAscending }
    }
}
