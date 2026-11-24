//
//  SheetParserTests.swift
//  CyrusLyricsTests
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation
import Testing
@testable import CyrusLyrics

struct SheetParserTests {
    @Test func groupsSongsByCategoryAndSubCategory() {
        let categories = SheetParser.categories(fromRows: [
            headerRow,
            ["Country", "Darius Rucker", "Wagon Wheel"],
            ["Country", "Darius Rucker", "Alright"],
            ["Country", "Johnny Cash", "Ring of Fire"],
            ["Disco", "ABBA", "Dancing Queen"],
        ])

        #expect(categories.map(\.name) == ["Country", "Disco"])
        #expect(categories[0].subCategories.map(\.name) == ["Darius Rucker", "Johnny Cash"])
        #expect(categories[0].subCategories[0].links.map(\.name) == ["Alright", "Wagon Wheel"])
        #expect(categories[1].subCategories[0].links.map(\.name) == ["Dancing Queen"])
    }

    @Test func skipsTheHeaderRow() {
        let categories = SheetParser.categories(fromRows: [headerRow])

        #expect(categories.isEmpty)
    }

    @Test func skipsRowsMissingRequiredColumns() {
        let categories = SheetParser.categories(fromRows: [
            headerRow,
            ["Country", "Darius Rucker"],
            ["Country", nil, "Wagon Wheel"],
            ["Country", "", "Wagon Wheel"],
            ["   ", "Darius Rucker", "Wagon Wheel"],
            [],
            ["Country", "Darius Rucker", "Wagon Wheel"],
        ])

        #expect(categories.count == 1)
        #expect(categories.links(in: .all).map(\.name) == ["Wagon Wheel"])
    }

    @Test func readsOptionalColumns() throws {
        let categories = SheetParser.categories(fromRows: [
            headerRow,
            ["Country", "Darius Rucker", "Wagon Wheel", "https://example.com/lyrics", "Headed down south", "https://open.spotify.com/track/1"],
        ])

        let link = try #require(categories.links(in: .all).first)
        #expect(link.url == "https://example.com/lyrics")
        #expect(link.lyrics == "Headed down south")
        #expect(link.spotifyUrl == "https://open.spotify.com/track/1")
        #expect(link.hasSavedLyrics)
        #expect(link.spotifyURL != nil)
    }

    @Test func fallsBackToAGoogleSearchWithoutAURL() throws {
        let categories = SheetParser.categories(fromRows: [
            headerRow,
            ["Country", "Darius Rucker", "Wagon Wheel", "", nil],
        ])

        let link = try #require(categories.links(in: .all).first)
        #expect(link.url == "https://www.google.com/search?q=Wagon+Wheel+by+Darius+Rucker+lyrics")
        #expect(link.lyrics.isEmpty)
        #expect(link.spotifyURL == nil)
    }

    @Test func trimsWhitespaceSoGroupsMatch() {
        let categories = SheetParser.categories(fromRows: [
            headerRow,
            ["Country ", "Darius Rucker", "Wagon Wheel"],
            ["Country", " Darius Rucker", "Alright\n"],
        ])

        #expect(categories.count == 1)
        #expect(categories[0].subCategories.count == 1)
        #expect(categories[0].subCategories[0].links.map(\.name) == ["Alright", "Wagon Wheel"])
    }

    @Test func sortsNamesTheWayTheFinderDoes() {
        let categories = SheetParser.categories(fromRows: [
            headerRow,
            ["rock", "A", "Song 10"],
            ["Pop", "B", "Song 2"],
            ["Alternative", "C", "song 1"],
            ["rock", "A", "Song 2"],
            ["rock", "A", "song 1"],
        ])

        #expect(categories.map(\.name) == ["Alternative", "Pop", "rock"])
        #expect(categories[2].subCategories[0].links.map(\.name) == ["song 1", "Song 2", "Song 10"])
    }

    @Test func readsRowsFromTheBackend() {
        let rows = SheetParser.rows(fromAPIValues: [["Genre", "Artist", "Song Title"], ["Country", "Darius Rucker", "Wagon Wheel"]])
        let categories = SheetParser.categories(fromRows: rows)

        #expect(categories.links(in: .all).map(\.name) == ["Wagon Wheel"])
    }

    // MARK: - gviz

    @Test func readsRowsFromAGvizResponse() throws {
        let response = String(decoding: gvizResponse(rows: [headerRow, ["Country", "Darius Rucker", "Wagon Wheel", nil]]), as: UTF8.self)

        let rows = try #require(SheetParser.rows(fromGvizResponse: response))
        #expect(rows.count == 2)
        #expect(rows[1] == ["Country", "Darius Rucker", "Wagon Wheel", nil])
    }

    @Test func readsNumberCellsAsText() throws {
        let response = """
        /*O_o*/
        google.visualization.Query.setResponse({"table":{"rows":[{"c":[{"v":"Pop"},{"v":"Prince"},{"v":1999.0,"f":"1999"}]},{"c":[{"v":"Pop"},{"v":"Prince"},{"v":7.0}]},{"c":[{"v":true},{"v":null},null]}]}});
        """

        let rows = try #require(SheetParser.rows(fromGvizResponse: response))
        #expect(rows[0] == ["Pop", "Prince", "1999"])
        #expect(rows[1] == ["Pop", "Prince", "7"])
        #expect(rows[2] == ["true", nil, nil])
    }

    @Test(arguments: [
        "",
        "<html>Sign in to continue</html>",
        "google.visualization.Query.setResponse({\"status\":\"error\"});",
        "} nothing here {",
    ])
    func rejectsUnexpectedGvizResponses(response: String) {
        #expect(SheetParser.rows(fromGvizResponse: response) == nil)
    }

    // MARK: - Default lyrics URL

    @Test func encodesSpecialCharactersInTheSearchURL() {
        let urlString = SheetParser.defaultLyricsURL(song: "Rock & Roll #1?", artist: "AC/DC + Beyoncé")

        #expect(urlString == "https://www.google.com/search?q=Rock+%26+Roll+%231%3F+by+AC%2FDC+%2B+Beyonc%C3%A9+lyrics")
        #expect(URL(string: urlString) != nil)
    }
}
