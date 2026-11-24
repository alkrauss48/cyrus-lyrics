//
//  GSheetStructs.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

// New Format

struct GoogleSheetNewCell : Decodable {
    var data: String?
    
    enum CodingKeys : String, CodingKey {
        case data = "v"
    }
}

struct GoogleSheetRow: Decodable {
    var c: [GoogleSheetNewCell?]
}

struct GoogleSheetTable: Decodable {
    var rows: [GoogleSheetRow]
}

struct GoogleSheetNewFormat: Decodable {
    var table: GoogleSheetTable
}
