//
//  LocalStore.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation
import OSLog

/// Caches app data in UserDefaults, which is what makes offline mode work.
///
/// Values are property-list encoded. Don't rename the keys without migrating
/// the existing values.
struct LocalStore {
    enum Key: String {
        case defaultFiles
        case userFiles
        case categories
        case activeFile
        /// Where the OAuth token was stored before it moved to the Keychain.
        case legacyOAuthToken = "oauthQuery"
        /// Set on first launch. UserDefaults is erased when the app is deleted
        /// but the Keychain isn't, so this tells a reinstall apart from an
        /// update.
        case hasLaunched
    }

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load<Value: Decodable>(_ type: Value.Type, for key: Key) -> Value? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }

        do {
            return try PropertyListDecoder().decode(type, from: data)
        } catch {
            Logger.storage.error("Couldn't decode cached \(key.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func save<Value: Encodable>(_ value: Value, for key: Key) {
        do {
            defaults.set(try PropertyListEncoder().encode(value), forKey: key.rawValue)
        } catch {
            Logger.storage.error("Couldn't encode \(key.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func string(for key: Key) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    func bool(for key: Key) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }

    func set(_ value: Bool, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    func remove(_ key: Key) {
        defaults.removeObject(forKey: key.rawValue)
    }
}
