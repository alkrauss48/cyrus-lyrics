//
//  GSheetStructs.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

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
