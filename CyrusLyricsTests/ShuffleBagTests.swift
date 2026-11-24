//
//  ShuffleBagTests.swift
//  CyrusLyricsTests
//
//  Created by Aaron Krauss on 11/24/26.
//

import Testing
@testable import CyrusLyrics

struct ShuffleBagTests {
    @Test func emptyBagReturnsNil() {
        var bag = ShuffleBag<Int>([])

        #expect(bag.isEmpty)
        #expect(bag.next() == nil)
    }

    @Test func usesEveryElementOnceEachRound() {
        let elements = Array(1...10)
        var bag = ShuffleBag(elements)

        for _ in 0..<5 {
            let round = (0..<elements.count).compactMap { _ in bag.next() }
            #expect(round.sorted() == elements)
        }
    }

    @Test func neverRepeatsAnElementBackToBack() {
        var bag = ShuffleBag([1, 2, 3])
        var previous = bag.next()

        for _ in 0..<300 {
            let current = bag.next()
            #expect(current != previous)
            previous = current
        }
    }

    @Test func singleElementRepeats() {
        var bag = ShuffleBag(["Only Song"])

        #expect(bag.next() == "Only Song")
        #expect(bag.next() == "Only Song")
    }
}
