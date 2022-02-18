//
//  OAuthSheetAdapter.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/16/22.
//

import Foundation

class OAuthSheetAdapter {
    public func processData(rows: [[String]]) -> [AppCategory] {
        var categories = [AppCategory]()
        
        for (rowIndex, row) in rows.enumerated() {
            // Skip the first row, since that's headings
            if rowIndex == 0 {
                continue
            }
            
            if (row.count < 3) {
                continue
            }

            let categoryCell = row[0]
            let subCategoryCell = row[1]
            let linkNameCell = row[2]
            let linkUrlCell = row.count >= 4 ? row[3] : nil
            let linkLyricsCell = row.count >= 5 ? row[4] : nil
            let linkSpotifyCell = row.count >= 6 ? row[5] : nil

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
