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
                    let stateManager = StateManager.Get()
                    
                    DispatchQueue.main.async {
                        stateManager.setOauthQuery(value: url.query!)
                        stateManager.listUserSheets()
                        stateManager.showLoginActionSheet = false
                    }
                }
        }
    }
}
