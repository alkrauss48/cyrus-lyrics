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
    @Published var defaultFiles: [APIFile] = [];

    
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
        
        // Load up the default files
        if let defaultFiles = deserializeStoredValueAs(key: "defaultFiles", type: [APIFile].self) {
            self.defaultFiles = defaultFiles
        } else {
            listDefaultSheets()
        }
    }
    
    private func deserializeStoredValueAs<T: Decodable>(key: String, type: T.Type) -> T? {
        if let data = UserDefaults.standard.value(forKey: key) as? Data {
            let decodedValue = try? PropertyListDecoder().decode(type, from: data)

            return decodedValue
        }
        
        return nil;
    }
    
    func setOauthQuery(value: String) {
        self.oauthQuery = value
        UserDefaults.standard.set(value, forKey: "oauthQuery")
    }
    
    func toggleMenu() {
        self.menuOpen.toggle()
    }
    
    func isLoggedIn() -> Bool {
        return !self.oauthQuery.isEmpty
    }
    
    func authUrl() -> URL {
        return URL(string: "https://api.cyruskrauss.com/oauth/google")!
    }
    
    func createSheetUrl(title: String) -> URL {
        return URL(string: "https://api.cyruskrauss.com/sheets/new?" + self.oauthQuery + "&title=" + title)!
    }
    
    func listUserSheets() -> Void {
        let requestUrl = URL(string: "https://api.cyruskrauss.com/sheets?" + self.oauthQuery)!
        
        makeRequest(url: requestUrl) { data in
            do {
                let result = try JSONDecoder().decode(APIListFilesResponse.self, from: data)
                DispatchQueue.main.async {
                    self.userFiles = result.files
                }
            } catch let responseError {
                print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
            }
        }
    }
    
    func listDefaultSheets() -> Void {
        let requestUrl = URL(string: "https://api.cyruskrauss.com/sheets/default")!
        
        makeRequest(url: requestUrl) { data in
            do {
                let result = try JSONDecoder().decode([APIFile].self, from: data)
                DispatchQueue.main.async {
                    self.defaultFiles = result
                }
                
                UserDefaults.standard.set(try? PropertyListEncoder().encode(result), forKey:"defaultFiles")
            } catch let responseError {
                print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
            }
        }
    }
    
    private func makeRequest(url: URL, callback: @escaping (Data) -> ()) {
        let request = URLRequest(url: url)
        
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
            
            callback(serverData)
        }

        // Run the task
        webTask.resume()
    }
}
