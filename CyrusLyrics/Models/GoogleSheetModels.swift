//
//  GoogleSheetModels.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import Foundation

/// The JSON inside a response from Google's public "gviz" sheet endpoint.
struct GvizResponse: Decodable, Sendable {
    struct Table: Decodable, Sendable {
        var rows: [Row]
    }

    struct Row: Decodable, Sendable {
        var c: [Cell?]
    }

    struct Cell: Decodable, Sendable {
        /// The cell's contents as text, or `nil` if the cell is empty.
        var value: String?

        private enum CodingKeys: String, CodingKey {
            case value = "v"
            case formattedValue = "f"
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Text cells only have "v". Number and date cells also have "f",
            // the value formatted the way the sheet displays it.
            if let text = try? container.decode(String.self, forKey: .value) {
                value = text
            } else if let formatted = try? container.decode(String.self, forKey: .formattedValue) {
                value = formatted
            } else if let number = try? container.decode(Double.self, forKey: .value) {
                value = number.formatted(.number.grouping(.never))
            } else if let bool = try? container.decode(Bool.self, forKey: .value) {
                value = String(bool)
            } else {
                value = nil
            }
        }
    }

    var table: Table
}
