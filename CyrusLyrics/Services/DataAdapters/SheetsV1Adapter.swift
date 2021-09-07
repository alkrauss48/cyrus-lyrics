//
//  SheetsV1Adapter.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 9/7/21.
//

// ** DEPRECATED **
// Seems to have stopped working in mid-August 2021

import Foundation

class SheetsV1Adapter: SheetsAdapter {
    var dataUrl = "https://spreadsheets.google.com/feeds/cells/1JfkF-N492ygBLMcHQhXUFl-MtlMGQz35Vco4caiVw9c/1/public/full?alt=json"

    func parseCategories(data: String!) -> [AppCategory] {
        let jsonData = data.data(using: .utf8)!
        let gSheet: GoogleSheetFormat = try! JSONDecoder().decode(GoogleSheetFormat.self, from: jsonData)

        let cells = gSheet.feed.entries.map { $0.cell }

        let rows = Dictionary(grouping: cells, by: { $0.row })

        return self.processData(rows: rows)
    }

    private func processData(rows: Dictionary<String, [GoogleSheetCell]>!) -> [AppCategory] {
        var categories = [AppCategory]()

        for (key, cells) in rows {
            // Skip the first row, since that's headings
            if key == "1" {
                continue
            }

            guard let categoryCell = cells.first(where: { $0.col == "1" }) else { continue }
            guard let subCategoryCell = cells.first(where: { $0.col == "2" }) else { continue }
            guard let linkNameCell = cells.first(where: { $0.col == "3" }) else { continue }
            let linkUrlCell = cells.first(where: { $0.col == "4" })
            let linkLyricsCell = cells.first(where: { $0.col == "5" })
            let linkSpotifyCell = cells.first(where: { $0.col == "6" })

            // Process the row's category
            var categoryIndex: Int
            let matchedCategoryIndex = categories.firstIndex(where: { $0.name == categoryCell.data })

            if (matchedCategoryIndex == nil) {
                let newCategory = AppCategory(
                    name: categoryCell.data,
                    subCategories: []
                )

                categories.append(newCategory)

                categoryIndex = categories.count - 1
            } else {
                categoryIndex = matchedCategoryIndex!
            }

            // Process the row's sub-category
            var subCategoryIndex: Int
            let matchedSubCategoryIndex = categories[categoryIndex].subCategories.firstIndex(where: { $0.name == subCategoryCell.data })

            if (matchedSubCategoryIndex == nil) {
                let newSubCategory = AppSubCategory(
                    name: subCategoryCell.data,
                    links: []
                )

                // Add the new sub-category and sort them all
                categories[categoryIndex].subCategories.append(newSubCategory)

                subCategoryIndex = categories[categoryIndex].subCategories.count - 1
            } else {
                subCategoryIndex = matchedSubCategoryIndex!
            }

            // Process the row's link
            let linkUrl = linkUrlCell == nil ? (
                Utilities.getDefaultGoogleUrl(name: linkNameCell.data, subCategory: subCategoryCell.data)
            ) : (
                linkUrlCell!.data
            )

            let linkLyrics = linkLyricsCell == nil ? "" : linkLyricsCell!.data
            let linkSpotifyUrl = linkSpotifyCell == nil ? "" : linkSpotifyCell!.data

            // Add the new link and sort them all
            categories[categoryIndex].subCategories[subCategoryIndex].links.append(
                AppLink(
                    name: linkNameCell.data,
                    url: linkUrl,
                    lyrics: linkLyrics,
                    spotifyUrl: linkSpotifyUrl
                )
            )
        }

        return categories
    }
}
