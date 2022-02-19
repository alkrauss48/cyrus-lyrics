//
//  FAQStructs.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/18/22.
//

import Foundation

struct FAQItem: Identifiable {
    let id = UUID()
    let name: String
    var items: [FAQItem]?

    static let items = [
        FAQItem(name: "What is CyrusLyrics?", items: [
            FAQItem(name: "Welcome! This app is about helping you quickly store, find, and add the lyrics of songs that you like to sing.")
        ]),
        FAQItem(name: "Who is Cyrus?", items: [
            FAQItem(name: "Cyrus is my son, and I like to sing to him. This app helps with that!")
        ]),
        FAQItem(name: "How are the lyrics found?", items: [
            FAQItem(name: "The lyrics are found via a simple Google search, with the ability to provide your own URL or lyrics for your own song lists.")
        ]),
        FAQItem(name: "How does the shuffle icon work?", items: [
            FAQItem(name: "The shuffle icon will shuffle at your current level. I.e. All songs, a single category, or a single sub-category.")
        ]),
        FAQItem(name: "Can I create my own song lists?", items: [
            FAQItem(name: "Absolutely! Go to the 'Set Data' page, click 'Login' followed by 'Create Sheet,' and a new Google Sheet will be created for you.")
        ]),
        FAQItem(name: "How do I add songs to my list?", items: [
            FAQItem(name: "After selecting your list, go to the 'Home' page and click 'Add Songs.' This will take you to your active list's Google Sheet. From there, you can follow the column prompts to add the right data")
        ]),
        FAQItem(name: "What do the 6 Google Sheet columns mean?", items: [
            FAQItem(name: "The first 3 are necessary for organizing your songs. The optional 'URL' column is for you to override when Google can't automatically show the song lyrics. The optional 'Lyrics' column is if you want to provide your own custom lyrics. Lastly, the optional 'Spotify URL' column is for you to put the Spotify Song Link, which will allow you to open the song in Spotify.")
        ]),
        FAQItem(name: "How do I update the app to show my updated songs?", items: [
            FAQItem(name: "After editing your Google Sheet, go to the 'Home' page and pull down to refresh.")
        ]),
        FAQItem(name: "Can I delete a song list?", items: [
            FAQItem(name: "Yes, you can delete a song list by deleting the Google Sheet on your Google account.")
        ]),
        FAQItem(name: "Why are Cyrus' Dad's Songs on here?", items: [
            FAQItem(name: "Hey, I'm the developer of this app, I can do what I want! It's my way of showing you that this is a real life app made by a real dad.")
        ]),
    ]
}
