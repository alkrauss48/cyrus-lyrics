//
//  LoadData.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

// Spreadsheet JSONifying based on: https://www.freecodecamp.org/news/cjn-google-sheets-as-json-endpoint/
// HTTP Request logic based on: https://www.appsdeveloperblog.com/http-get-request-example-in-swift/

import Foundation
import Combine
import SwiftUI

// Google Sheet workflow found here:
// https://benborgers.com/posts/google-sheets-json

//let DATA_URL = "https://spreadsheets.google.com/feeds/cells/1JfkF-N492ygBLMcHQhXUFl-MtlMGQz35Vco4caiVw9c/1/public/full?alt=json"

let DATA_URL = "https://docs.google.com/spreadsheets/d/1JfkF-N492ygBLMcHQhXUFl-MtlMGQz35Vco4caiVw9c/gviz/tq?tqx=out:json"


class DataManager: ObservableObject {
    @Published var categories = [AppCategory]()
  
    init() {
        if let data = UserDefaults.standard.value(forKey:"categories") as? Data {
            loadAppData(data: data)
        } else {
            queryAppData()
        }
    }
    
    func loadAppData(data: Data) {
        let existingCategories = try? PropertyListDecoder().decode(Array<AppCategory>.self, from: data)
        
        if (existingCategories == nil) {
            queryAppData()
            return
        }
        
        setCategories(newCategories: existingCategories!)
    }
  
    func setCategories(newCategories: [AppCategory]) {
        // Publish the categories so the main thread and view will trigger UI updates
        DispatchQueue.main.async {
            self.categories = newCategories
        }
    }

    func queryAppData() -> Void {
        // Create URL
        let url = URL(string: DATA_URL)
        guard let requestUrl = url else { fatalError() }

        // Create URL Request
        var request = URLRequest(url: requestUrl)

        // Specify HTTP Method to use
        request.httpMethod = "GET"

        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            // Check if Error took place
            if let error = error {
                print("Error took place \(error)")
                return
            }

            // Read HTTP Response Status code
            if let response = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(response.statusCode)")
            }

            // Convert HTTP Response Data to a simple String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
//                self.parseOldAppData(data: dataString)
                self.parseAppData(data: dataString)
            }

        }

        task.resume()
    }
    
    func parseAppData(data: String!) {
        let responseData = data.data(using: .utf8)!
        
        let start = responseData.index(responseData.startIndex, offsetBy: 47)
        let end = responseData.index(responseData.endIndex, offsetBy: -2)
        let range = start..<end

        let jsonData = responseData[range]
//        let jsonData = String(mySubstring)

        
        let gSheet: GoogleSheetNewFormat = try! JSONDecoder().decode(GoogleSheetNewFormat.self, from: jsonData)

        let rows = gSheet.table.rows.map { $0.c }

        self.processAppData(rows: rows)
    }

//    func parseOldAppData(data: String!) {
//        let jsonData = data.data(using: .utf8)!
//        let gSheet: GoogleSheetFormat = try! JSONDecoder().decode(GoogleSheetFormat.self, from: jsonData)
//
//        let cells = gSheet.feed.entries.map { $0.cell }
//
//        let rows = Dictionary(grouping: cells, by: { $0.row })
//
//        self.processOldAppData(rows: rows)
//    }
    
    func processAppData(rows: [[GoogleSheetNewCell?]]) {
        var tempCategories = [AppCategory]()
        
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
            let matchedCategoryIndex = tempCategories.firstIndex(where: { $0.name == categoryCell })

            if (matchedCategoryIndex == nil) {
                let newCategory = AppCategory(
                    name: categoryCell,
                    subCategories: []
                )

                tempCategories.append(newCategory)

                categoryIndex = tempCategories.count - 1
            } else {
                categoryIndex = matchedCategoryIndex!
            }

            // Process the row's sub-category
            var subCategoryIndex: Int
            let matchedSubCategoryIndex = tempCategories[categoryIndex].subCategories.firstIndex(where: { $0.name == subCategoryCell })

            if (matchedSubCategoryIndex == nil) {
                let newSubCategory = AppSubCategory(
                    name: subCategoryCell,
                    links: []
                )

                // Add the new sub-category and sort them all
                tempCategories[categoryIndex].subCategories.append(newSubCategory)

                subCategoryIndex = tempCategories[categoryIndex].subCategories.count - 1
            } else {
                subCategoryIndex = matchedSubCategoryIndex!
            }
            
            // Add the new link and sort them all
            tempCategories[categoryIndex].subCategories[subCategoryIndex].links.append(
                AppLink(
                    name: linkNameCell,
                    url: linkUrlCell ?? self.getDefaultGoogleUrl(name: linkNameCell, subCategory: subCategoryCell),
                    lyrics: linkLyricsCell ?? "",
                    spotifyUrl: linkSpotifyCell ?? ""
                )
            )
        }
        
        // Sort the categories by name
        tempCategories.sort { $0.name < $1.name }
        
        setCategories(newCategories: tempCategories)
        
        // Save the categories in UserDefaults
        UserDefaults.standard.set(try? PropertyListEncoder().encode(tempCategories), forKey:"categories")
    }

//    func processOldAppData(rows: Dictionary<String, [GoogleSheetCell]>!) {
//        var tempCategories = [AppCategory]()
//
//        for (key, cells) in rows {
//            // Skip the first row, since that's headings
//            if key == "1" {
//                continue
//            }
//
//            guard let categoryCell = cells.first(where: { $0.col == "1" }) else { continue }
//            guard let subCategoryCell = cells.first(where: { $0.col == "2" }) else { continue }
//            guard let linkNameCell = cells.first(where: { $0.col == "3" }) else { continue }
//            let linkUrlCell = cells.first(where: { $0.col == "4" })
//            let linkLyricsCell = cells.first(where: { $0.col == "5" })
//            let linkSpotifyCell = cells.first(where: { $0.col == "6" })
//
//            // Process the row's category
//            var categoryIndex: Int
//            let matchedCategoryIndex = tempCategories.firstIndex(where: { $0.name == categoryCell.data })
//
//            if (matchedCategoryIndex == nil) {
//                let newCategory = AppCategory(
//                    name: categoryCell.data,
//                    subCategories: []
//                )
//
//                tempCategories.append(newCategory)
//
//                categoryIndex = tempCategories.count - 1
//            } else {
//                categoryIndex = matchedCategoryIndex!
//            }
//
//            // Process the row's sub-category
//            var subCategoryIndex: Int
//            let matchedSubCategoryIndex = tempCategories[categoryIndex].subCategories.firstIndex(where: { $0.name == subCategoryCell.data })
//
//            if (matchedSubCategoryIndex == nil) {
//                let newSubCategory = AppSubCategory(
//                    name: subCategoryCell.data,
//                    links: []
//                )
//
//                // Add the new sub-category and sort them all
//                tempCategories[categoryIndex].subCategories.append(newSubCategory)
//
//                subCategoryIndex = tempCategories[categoryIndex].subCategories.count - 1
//            } else {
//                subCategoryIndex = matchedSubCategoryIndex!
//            }
//
//            // Process the row's link
//            let linkUrl = linkUrlCell == nil ? (
//                self.getDefaultGoogleUrl(subCategoryCell: subCategoryCell, linkNameCell: linkNameCell)
//            ) : (
//                linkUrlCell!.data
//            )
//
//            let linkLyrics = linkLyricsCell == nil ? "" : linkLyricsCell!.data
//            let linkSpotifyUrl = linkSpotifyCell == nil ? "" : linkSpotifyCell!.data
//
//            // Add the new link and sort them all
//            tempCategories[categoryIndex].subCategories[subCategoryIndex].links.append(
//                AppLink(
//                    name: linkNameCell.data,
//                    url: linkUrl,
//                    lyrics: linkLyrics,
//                    spotifyUrl: linkSpotifyUrl
//                )
//            )
//        }
//
//        // Sort the categories by name
//        tempCategories.sort { $0.name < $1.name }
//
//        setCategories(newCategories: tempCategories)
//
//        // Save the categories in UserDefaults
//        UserDefaults.standard.set(try? PropertyListEncoder().encode(tempCategories), forKey:"categories")
//    }

    func getDefaultGoogleUrl(name: String, subCategory: String) -> String {
        // Make the URL google-able
        let url = "https://www.google.com/search?q=\(name) by \(subCategory) lyrics"
        let serializedUrl = url.replacingOccurrences(of: " ", with: "+")
        
        return serializedUrl
    }
}
