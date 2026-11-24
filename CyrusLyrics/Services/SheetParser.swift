//
//  SheetParser.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 9/7/21.
//

import Foundation

/// Turns Google Sheet rows into categories.
///
/// Every list uses the same columns, and row 1 holds the headers:
///
///     Category | Sub-category | Song name | URL | Lyrics | Spotify URL
///
/// The last three columns are optional. Rows missing any of the first three
/// are skipped. Songs without a URL fall back to a Google search.
enum SheetParser {
    static func categories(fromRows rows: [[String?]]) -> [AppCategory] {
        var categories: [AppCategory] = []
        var categoryIndexes: [String: Int] = [:]
        var subCategoryIndexes: [String: [String: Int]] = [:]

        for row in rows.dropFirst() {
            func cell(_ index: Int) -> String? {
                guard index < row.count,
                      let value = row[index]?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !value.isEmpty else {
                    return nil
                }

                return value
            }

            guard let categoryName = cell(0),
                  let subCategoryName = cell(1),
                  let songName = cell(2) else {
                continue
            }

            let categoryIndex: Int
            if let index = categoryIndexes[categoryName] {
                categoryIndex = index
            } else {
                categoryIndex = categories.count
                categoryIndexes[categoryName] = categoryIndex
                categories.append(AppCategory(name: categoryName, subCategories: []))
            }

            let subCategoryIndex: Int
            if let index = subCategoryIndexes[categoryName]?[subCategoryName] {
                subCategoryIndex = index
            } else {
                subCategoryIndex = categories[categoryIndex].subCategories.count
                subCategoryIndexes[categoryName, default: [:]][subCategoryName] = subCategoryIndex
                categories[categoryIndex].subCategories.append(AppSubCategory(name: subCategoryName, links: []))
            }

            categories[categoryIndex].subCategories[subCategoryIndex].links.append(
                AppLink(
                    name: songName,
                    url: cell(3) ?? defaultLyricsURL(song: songName, artist: subCategoryName),
                    lyrics: cell(4) ?? "",
                    spotifyUrl: cell(5) ?? ""
                )
            )
        }

        return categories.sortedByName()
    }

    /// Rows from a response from the backend's `GET /sheets/:id`.
    static func rows(fromAPIValues values: [[String]]) -> [[String?]] {
        values.map { row in row.map { $0 } }
    }

    /// Rows from a response from Google's public "gviz" endpoint, or `nil` if
    /// the response isn't in the expected format.
    static func rows(fromGvizResponse response: String) -> [[String?]]? {
        // The endpoint wraps its JSON in a JSONP callback, like
        // `/*O_o*/\ngoogle.visualization.Query.setResponse({...});`.
        guard let start = response.firstIndex(of: "{"),
              let end = response.lastIndex(of: "}"),
              start < end else {
            return nil
        }

        let json = Data(response[start...end].utf8)

        guard let gviz = try? JSONDecoder().decode(GvizResponse.self, from: json) else {
            return nil
        }

        return gviz.table.rows.map { row in row.c.map { $0?.value } }
    }

    /// A Google search for the song's lyrics.
    static func defaultLyricsURL(song: String, artist: String) -> String {
        // Percent-encode everything except unreserved characters, so titles
        // containing "&", "+", "#", "?", or non-ASCII characters still
        // produce a valid search URL.
        let allowed = CharacterSet(charactersIn:
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~ ")

        let query = "\(song) by \(artist) lyrics"
        let encodedQuery = (query.addingPercentEncoding(withAllowedCharacters: allowed) ?? query)
            .replacingOccurrences(of: " ", with: "+")

        return "https://www.google.com/search?q=" + encodedQuery
    }
}
