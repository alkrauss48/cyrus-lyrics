//
//  CyrusLyricsApp.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

@main
struct CyrusLyricsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                  // handle the URL that must be opened
                    print("onOpenURL")
                    print(url)
                }
        }
    }
}
