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
    @Published var rootView: String = "CATEGORY_LIST_VIEW";

    static var stateManager = StateManager()
    
    static func Get() -> StateManager {
        return self.stateManager
    }
    
    func toggleMenu() {
        self.menuOpen.toggle()
    }
}
