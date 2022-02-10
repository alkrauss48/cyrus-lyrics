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

// Old format

struct GoogleSheetCell: Decodable {
    var row: String;
    var col: String;
    var data: String;
    
    enum CodingKeys : String, CodingKey {
        case data = "inputValue"
        case row = "row"
        case col = "col"
    }
}

struct GoogleSheetEntry: Decodable {
    var cell: GoogleSheetCell
    
    enum CodingKeys : String, CodingKey {
        case cell = "gs$cell"
    }
}

struct GoogleSheetFeed: Decodable {
    var entries: [GoogleSheetEntry]
    
    enum CodingKeys : String, CodingKey {
        case entries = "entry"
    }
}

struct GoogleSheetFormat: Decodable {
    var feed: GoogleSheetFeed
}

