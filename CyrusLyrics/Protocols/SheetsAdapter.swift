//
//  SheetsAdapter.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 9/7/21.
//

import Foundation

protocol SheetsAdapter {
    func parseCategories(data: String!) -> [AppCategory]
    func getDataUrl(sheetId: String) -> String
}
