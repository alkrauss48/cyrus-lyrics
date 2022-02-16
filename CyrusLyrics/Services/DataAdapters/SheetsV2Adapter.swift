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
    
    func parseCategories(data: String!) -> [AppCategory] {
        let responseData = data.data(using: .utf8)!
        
        let start = responseData.index(responseData.startIndex, offsetBy: 47)
        let end = responseData.index(responseData.endIndex, offsetBy: -2)
        let range = start..<end

        let jsonData = responseData[range]
        
        let gSheet: GoogleSheetNewFormat = try! JSONDecoder().decode(GoogleSheetNewFormat.self, from: jsonData)

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
            
            if (row.count < 3) {
                continue
            }

            guard let categoryCell = row[0]?.data else { continue }
            guard let subCategoryCell = row[1]?.data else { continue }
            guard let linkNameCell = row[2]?.data else { continue }
            let linkUrlCell = row[3]?.data
            let linkLyricsCell = row[4]?.data
            let linkSpotifyCell = row[5]?.data

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
