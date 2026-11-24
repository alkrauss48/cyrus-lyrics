//
//  Logging.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 11/24/26.
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.cyruskrauss.cyruslyrics"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let auth = Logger(subsystem: subsystem, category: "auth")
}
