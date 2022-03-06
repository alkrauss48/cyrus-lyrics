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
        FAQItem(name: "What is the best way to learn how to use CyrusLyrics?", items: [
            FAQItem(name: "That would be by clicking the 'View Tutorials' button at the bottom of this page.")
        ]),
        FAQItem(name: "What is CyrusLyrics?", items: [
            FAQItem(name: "Welcome! This app is about helping you quickly store, find, and add the lyrics of songs that you like to sing.")
        ]),
        FAQItem(name: "How is this app's size so small?", items: [
            FAQItem(name: "Thanks for noticing! There are no ads, no external plugins in the code, and none of your personal data is stored, so this app is tiny as can be.")
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
        FAQItem(name: "How do I create my own song lists?", items: [
            FAQItem(name: "Go to the 'Change List' page, click 'Login' followed by 'Create List.' From there, enter your desired list name, and a new Google Sheet will be created for you on your Google account.")
        ]),
        FAQItem(name: "Where is the data stored?", items: [
            FAQItem(name: "All of your CyrusLyrics data is stored in Google Sheets that you own, under your Google account. This gives you full control of the data.")
        ]),
        FAQItem(name: "Do I need the Google Sheets app installed?", items: [
            FAQItem(name: "You only need Google Sheets installed to edit your lists on your iOS device. You can always use the Google Sheets website instead.")
        ]),
        FAQItem(name: "How do I add songs to my list?", items: [
            FAQItem(name: "After selecting your list, go to the 'Home' page and click 'Add Songs.' This will take you to your active list's Google Sheet. From there, you can follow the column prompts to add the right data.")
        ]),
        FAQItem(name: "How do I edit or delete my lists?", items: [
            FAQItem(name: "From the 'Change List' page, swipe one of your lists to the left to show the 'Edit' and 'Delete' buttons. If you don't have the Google Sheets app installed, the 'View' button will show instead of 'Edit'.")
        ]),
        FAQItem(name: "What do the 6 Google Sheet columns mean?", items: [
            FAQItem(name: "For this one, I recommend viewing the various tutorials over editing your lists."),
            FAQItem(name: "The first 3 columns are necessary for organizing your songs. The optional 'URL' column is for you to override the lyrics web page if Google can't automatically display the song lyrics. The optional 'Lyrics' column is if you want to provide your own custom lyrics. Lastly, the optional 'Spotify URL' column is for you to put the Spotify Song Link, which will allow you to open the song in Spotify.")
        ]),
        FAQItem(name: "How do I refresh to show my updated songs?", items: [
            FAQItem(name: "After editing your Google Sheet, go to the 'Home' page and pull down to refresh.")
        ]),
        FAQItem(name: "How do I restore a deleted list?", items: [
            FAQItem(name: "Deleting a list through the app will send it to your Google Drive trash, which will allow you 30 days to restore. If you restore the sheet on Google Drive, just pull down on the 'Change List' page to refresh, and your list will show back up.")
        ]),
        FAQItem(name: "How do I view the preloaded lists in Google Sheets?", items: [
            FAQItem(name: "From the 'Change List' page, swipe one of the preloaded lists to the left and click the 'View' button.")
        ]),
        FAQItem(name: "Can CyrusLyrics work offline?", items: [
            FAQItem(name: "Your lists and songs will still show without an internet connection, but CyrusLyrics will only be able to show the song lyrics that you have manually added via the 'Lyrics' column in the Google Sheet.")
        ]),
        FAQItem(name: "Why are Cyrus' Dad's Songs on here?", items: [
            FAQItem(name: "Hey, I'm the developer of this app, I can do what I want! It's my way of showing you that this is a real life app made by a real dad.")
        ]),
        FAQItem(name: "How can I give feedback on this app?", items: [
            FAQItem(name: "Thanks for asking! Please review it in the App Store, or feel free to email me (Aaron) at alkrauss48@gmail.com.")
        ]),
    ]
}
