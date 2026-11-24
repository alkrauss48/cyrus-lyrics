//
//  SheetsV2Adapter.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 9/7/21.
//

// Implemented after SheetsV1Adapter stopped working
//
// Google Sheet workflow found here:
// https://benborgers.com/posts/google-sheets-json

import Foundation

class SheetsV2Adapter: SheetsAdapter {
    
    func getDataUrl(sheetId: String) -> String {
        return "https://docs.google.com/spreadsheets/d/" + sheetId + "/gviz/tq?tqx=out:json"
    }
    
    func parseCategories(data: String!) -> [AppCategory]? {
        guard let data = data else {
            return nil
        }

        // The gviz endpoint wraps its JSON in a JSONP callback, e.g.
        // `/*O_o*/\ngoogle.visualization.Query.setResponse({...});`.
        // Take everything from the first "{" to the last "}" instead of
        // relying on a fixed-length prefix and suffix.
        guard let start = data.firstIndex(of: "{"),
              let end = data.lastIndex(of: "}"),
              start < end else {
            print("Unexpected Google Sheets response format")
            return nil
        }

        let jsonData = Data(data[start...end].utf8)

        guard let gSheet = try? JSONDecoder().decode(GoogleSheetNewFormat.self, from: jsonData) else {
            print("Unable to decode Google Sheets response")
            return nil
        }

        let rows = gSheet.table.rows.map { $0.c }

        return self.processData(rows: rows)
    }

    private func processData(rows: [[GoogleSheetNewCell?]]) -> [AppCategory] {
        var categories = [AppCategory]()

        for (rowIndex, row) in rows.enumerated() {
            // Skip the first row, since that's headings
            if rowIndex == 0 {
                continue
            }

            // Safely read a cell, since rows may have fewer than 6 columns
            func cell(_ index: Int) -> String? {
                guard index < row.count, let value = row[index]?.data, !value.isEmpty else {
                    return nil
                }

                return value
            }

            guard let categoryCell = cell(0) else { continue }
            guard let subCategoryCell = cell(1) else { continue }
            guard let linkNameCell = cell(2) else { continue }
            let linkUrlCell = cell(3)
            let linkLyricsCell = cell(4)
            let linkSpotifyCell = cell(5)

            // Process the row's category
            var categoryIndex: Int
            let matchedCategoryIndex = categories.firstIndex(where: { $0.name == categoryCell })

            if (matchedCategoryIndex == nil) {
                let newCategory = AppCategory(
                    name: categoryCell,
                    subCategories: []
                )

                categories.append(newCategory)

                categoryIndex = categories.count - 1
            } else {
                categoryIndex = matchedCategoryIndex!
            }

            // Process the row's sub-category
            var subCategoryIndex: Int
            let matchedSubCategoryIndex = categories[categoryIndex].subCategories.firstIndex(where: { $0.name == subCategoryCell })

            if (matchedSubCategoryIndex == nil) {
                let newSubCategory = AppSubCategory(
                    name: subCategoryCell,
                    links: []
                )

                // Add the new sub-category and sort them all
                categories[categoryIndex].subCategories.append(newSubCategory)

                subCategoryIndex = categories[categoryIndex].subCategories.count - 1
            } else {
                subCategoryIndex = matchedSubCategoryIndex!
            }
            
            // Add the new link and sort them all
            categories[categoryIndex].subCategories[subCategoryIndex].links.append(
                AppLink(
                    name: linkNameCell,
                    url: linkUrlCell ?? Utilities.getDefaultGoogleUrl(name: linkNameCell, subCategory: subCategoryCell),
                    lyrics: linkLyricsCell ?? "",
                    spotifyUrl: linkSpotifyCell ?? ""
                )
            )
        }
        
        return categories
    }
}
