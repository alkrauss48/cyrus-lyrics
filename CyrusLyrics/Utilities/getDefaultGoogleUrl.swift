//
//  getDefaultGoogleUrl.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 9/7/21.
//

import Foundation

class Utilities {
    static func getDefaultGoogleUrl(name: String, subCategory: String) -> String {
        // Make the URL google-able. Percent-encode everything except
        // unreserved characters, so titles containing "&", "+", "#", "?",
        // or non-ASCII characters still produce a valid search URL.
        let allowed = CharacterSet(charactersIn:
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~ ")

        let query = "\(name) by \(subCategory) lyrics"
        let encodedQuery = (query.addingPercentEncoding(withAllowedCharacters: allowed) ?? query)
            .replacingOccurrences(of: " ", with: "+")

        return "https://www.google.com/search?q=" + encodedQuery
    }
}
