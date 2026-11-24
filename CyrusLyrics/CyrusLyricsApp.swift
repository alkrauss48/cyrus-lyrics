//
//  CyrusLyricsApp.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

@main
struct CyrusLyricsApp: App {
    @State private var stateManager = StateManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(stateManager)
                .task {
                    await stateManager.start()
                }
                .onOpenURL { url in
                    // Sign-in normally finishes inside the web authentication
                    // session. This handles the callback if iOS opens the app
                    // with it directly instead.
                    Task {
                        await stateManager.signIn(callbackURL: url)
                    }
                }
        }
    }
}
