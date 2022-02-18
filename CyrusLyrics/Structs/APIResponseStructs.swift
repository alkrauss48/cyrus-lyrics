//
//  APIResponseStructs.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/10/22.
//

import Foundation

struct APIFile : Hashable, Codable {
    var id: String
    var name: String
}

struct APIListFilesResponse : Decodable, Hashable {
    var files: [APIFile]
}

struct APIGetSheetResponse : Decodable, Hashable {
    var majorDimension: String
    var range: String
    var values: [[String]]
}
