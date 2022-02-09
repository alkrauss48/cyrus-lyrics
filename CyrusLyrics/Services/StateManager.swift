//
//  StateManager.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import Foundation
import SwiftUI

class StateManager: ObservableObject {
    @Published var menuOpen: Bool = false
    @Published var rootView: String = StateManager.CATEGORY_LIST_VIEW;
    @Published var oauthQuery: String = "";
    
    static var CATEGORY_LIST_VIEW = "CATEGORY_LIST_VIEW"
    static var SET_DATA_VIEW = "SET_DATA_VIEW"
    
    static var stateManager = StateManager()
    
    static func Get() -> StateManager {
        return self.stateManager
    }
    
    init() {
        if let value = UserDefaults.standard.string(forKey: "oauthQuery") {
            self.oauthQuery = value
        }
    }
    
    func setOauthQuery(value: String) {
        self.oauthQuery = value
        UserDefaults.standard.set(value, forKey: "oauthQuery")
    }
    
    func toggleMenu() {
        self.menuOpen.toggle()
    }
    
    func authUrl() -> URL {
        return URL(string: "https://api.cyruskrauss.com/oauth/google")!
    }
    
    func createSheetUrl() -> URL {
        return URL(string: "https://api.cyruskrauss.com/sheets/new?" + self.oauthQuery)!
    }
}
