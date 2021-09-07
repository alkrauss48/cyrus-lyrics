//
//  getDefaultGoogleUrl.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 9/7/21.
//

import Foundation

class Utilities {
    static func getDefaultGoogleUrl(name: String, subCategory: String) -> String {
        // Make the URL google-able
        let url = "https://www.google.com/search?q=\(name) by \(subCategory) lyrics"
        let serializedUrl = url.replacingOccurrences(of: " ", with: "+")
        
        return serializedUrl
    }
}
