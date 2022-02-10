//
//  APIResponseStructs.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/10/22.
//

import Foundation

struct APIFile : Decodable, Hashable {
    var id: String
    var name: String
}

struct APIListFilesResponse : Decodable, Hashable {
    var files: [APIFile]
}
