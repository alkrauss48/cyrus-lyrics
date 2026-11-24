//
//  LibraryTests.swift
//  CyrusLyricsTests
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation
import Testing
@testable import CyrusLyrics

struct LibraryTests {
    let categories = SheetParser.categories(fromRows: [
        headerRow,
        ["Country", "Darius Rucker", "Wagon Wheel"],
        ["Country", "Johnny Cash", "Ring of Fire"],
        ["Disco", "ABBA", "Dancing Queen"],
    ])

    @Test func allScopeIncludesEverySong() {
        #expect(Set(categories.links(in: .all).map(\.name)) == ["Wagon Wheel", "Ring of Fire", "Dancing Queen"])
    }

    @Test func categoryScopeIncludesOnlyThatCategory() {
        let country = categories[0]

        #expect(Set(categories.links(in: .category(country.id)).map(\.name)) == ["Wagon Wheel", "Ring of Fire"])
    }

    @Test func subCategoryScopeIncludesOnlyThatSubCategory() {
        let johnnyCash = categories[0].subCategories[1]

        #expect(categories.links(in: .subCategory(johnnyCash.id)).map(\.name) == ["Ring of Fire"])
    }

    @Test func unknownScopeIsEmpty() {
        #expect(categories.links(in: .category(UUID())).isEmpty)
    }

    @Test func cachedDataRoundTripsThroughPropertyLists() throws {
        let data = try PropertyListEncoder().encode(categories)
        let decoded = try PropertyListDecoder().decode([AppCategory].self, from: data)

        #expect(decoded == categories)
    }
}
