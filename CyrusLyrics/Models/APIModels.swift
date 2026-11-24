//
//  APIModels.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/10/22.
//

import UIKit

/// A song list, which is a Google Sheet.
struct APIFile: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var name: String

    /// The sheet in a web browser.
    var webURL: URL? {
        URL(string: "https://docs.google.com/spreadsheets/d/\(id)")
    }

    /// The sheet in the Google Sheets app.
    var sheetsAppURL: URL? {
        URL(string: "googlesheets://https://docs.google.com/spreadsheets/d/\(id)")
    }

    /// Google's public JSON endpoint for the sheet. It only works for sheets
    /// shared publicly, like the preloaded lists.
    var publicDataURL: URL? {
        URL(string: "https://docs.google.com/spreadsheets/d/\(id)/gviz/tq?tqx=out:json")
    }
}

/// The response from `GET /sheets`.
struct APIListFilesResponse: Decodable, Sendable {
    var files: [APIFile]
}

/// The response from `GET /sheets/:id`, which mirrors the Google Sheets API.
struct APIGetSheetResponse: Decodable, Sendable {
    /// Google leaves out `values` when the sheet is empty.
    var values: [[String]]?
}

@MainActor
enum GoogleSheetsApp {
    /// Whether the Google Sheets app is installed. This relies on
    /// `googlesheets` being listed in `LSApplicationQueriesSchemes`.
    static var isInstalled: Bool {
        guard let url = URL(string: "googlesheets://") else {
            return false
        }

        return UIApplication.shared.canOpenURL(url)
    }
}
