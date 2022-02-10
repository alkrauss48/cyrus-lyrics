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
    @Published var userFiles: [APIFile] = [];
    
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
    
    func createSheetUrl(title: String) -> URL {
        return URL(string: "https://api.cyruskrauss.com/sheets/new?" + self.oauthQuery + "&title=" + title)!
    }
    
    func listSheetsUrl() -> URL {
        return URL(string: "https://api.cyruskrauss.com/sheets?" + self.oauthQuery)!
    }
    
    func listSheets() -> Void {
        let requestUrl = self.listSheetsUrl()
        
        let request = URLRequest(url: requestUrl)
        
        // Create the session object
        let session = URLSession.shared
        
        // Create a task using the session object, to run and return completion handler
        let webTask = session.dataTask(with: request) {data, response, error in
            guard error == nil else {
                print(error?.localizedDescription ?? "Response Error")
                return
            }
            guard let serverData = data else {
                print("server data error")
                return
            }
            do {
//                if let requestJson = try JSONSerialization.jsonObject(with: serverData, options: .mutableContainers) as? [String: Any]{
//                    print("Response: \(requestJson)")
//                } else {
//                    print("failed")
//                }
                let result = try JSONDecoder().decode(APIListFilesResponse.self, from: serverData)
                DispatchQueue.main.async {
                    self.userFiles = result.files
                }
            } catch let responseError {
                print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
                let message = String(bytes: serverData, encoding: .ascii)
                print(message as Any)
            }
        }

        // Run the task
        webTask.resume()
    }
}
