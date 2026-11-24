//
//  TokenStoreTests.swift
//  CyrusLyricsTests
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation
import Testing
@testable import CyrusLyrics

struct TokenStoreTests {
    let tokenStore = TokenStore(service: "test-\(UUID().uuidString)")

    @Test func savesLoadsAndDeletesTheToken() {
        defer { tokenStore.delete() }

        #expect(tokenStore.load() == nil)

        tokenStore.save("first")
        #expect(tokenStore.load() == "first")

        tokenStore.save("second")
        #expect(tokenStore.load() == "second")

        tokenStore.delete()
        #expect(tokenStore.load() == nil)
    }
}
