//
//  SheetsAdapter.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 9/7/21.
//

import Foundation

protocol SheetsAdapter {
    var dataUrl: String { get set }
    func parseCategories(data: String!) -> [AppCategory]
}
