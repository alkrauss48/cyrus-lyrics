//
//  TokenStore.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation
import OSLog
import Security

/// Keeps the backend's OAuth token in the Keychain.
struct TokenStore: Sendable {
    let service: String

    init(service: String = "com.cyruskrauss.cyruslyrics.oauth") {
        self.service = service
    }

    func load() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                Logger.storage.error("Couldn't read the token from the Keychain: \(status)")
            }

            return nil
        }

        return String(decoding: data, as: UTF8.self)
    }

    func save(_ token: String) {
        let data = Data(token.utf8)
        var status = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if status == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            status = SecItemAdd(query as CFDictionary, nil)
        }

        if status != errSecSuccess {
            Logger.storage.error("Couldn't save the token to the Keychain: \(status)")
        }
    }

    func delete() {
        let status = SecItemDelete(baseQuery as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            Logger.storage.error("Couldn't delete the token from the Keychain: \(status)")
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "oauthToken",
        ]
    }
}
