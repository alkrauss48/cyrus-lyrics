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
                        stateManager.showLoginActionSheet = false

                        guard let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                            return
                        }

                        let queryItems = urlComponent.queryItems

                        guard let token = queryItems?.first(where: { $0.name == "token" })?.value else {
                            return
                        }

                        stateManager.setOauthQuery(value: token)
                        stateManager.listUserSheets()
                    }
                }
        }
    }
}
