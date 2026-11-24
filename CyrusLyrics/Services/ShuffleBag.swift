//
//  ShuffleBag.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/19/21.
//

/// Hands out elements in a random order without repeating any until all of
/// them have been used, then starts a new round.
struct ShuffleBag<Element: Equatable> {
    private let elements: [Element]
    private var remaining: [Element] = []
    private var lastElement: Element?

    init(_ elements: [Element]) {
        self.elements = elements
    }

    var isEmpty: Bool {
        elements.isEmpty
    }

    mutating func next() -> Element? {
        if remaining.isEmpty {
            remaining = elements.shuffled()

            // Don't hand out the same element twice in a row when a new
            // round starts.
            if remaining.count > 1, remaining.last == lastElement {
                remaining.swapAt(0, remaining.count - 1)
            }
        }

        lastElement = remaining.popLast()
        return lastElement
    }
}

extension ShuffleBag: Sendable where Element: Sendable {}
