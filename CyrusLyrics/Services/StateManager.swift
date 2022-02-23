//
//  StateManager.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import Foundation
import SwiftUI

class StateManager: ObservableObject {
    @Environment(\.openURL) var openURL

    @Published var menuOpen: Bool = false
    @Published var rootView: String = StateManager.CATEGORY_LIST_VIEW
    @Published var oauthQuery: String = ""
    @Published var userFiles: [APIFile] = []
    @Published var defaultFiles: [APIFile] = []
    @Published var categories = [AppCategory]()
    @Published var activeFile: APIFile?
    @Published var isCreatingSheet: Bool = false
    
    var dataAdapter = SheetsV2Adapter()
    var oauthDataAdapter = OAuthSheetAdapter()
    
    static var CATEGORY_LIST_VIEW = "CATEGORY_LIST_VIEW"
    static var SET_DATA_VIEW = "SET_DATA_VIEW"
    static var HOW_IT_WORKS_VIEW = "HOW_IT_WORKS_VIEW"

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
        
        // Load up the user's files, if logged in
        if (self.isLoggedIn()) {
            if let userFiles = deserializeStoredValueAs(key: "userFiles", type: [APIFile].self) {
                self.userFiles = userFiles
            } else {
                listUserSheets()
            }
        }
        
        // Load up the active file
        if let storedActiveFile = deserializeStoredValueAs(key: "activeFile", type: APIFile.self) {
            DispatchQueue.main.async {
                self.activeFile = storedActiveFile
            }
        }
        
        // Load up app categories
        if let categories = deserializeStoredValueAs(key: "categories", type: [AppCategory].self) {
            setCategories(newCategories: categories)
        } else {
            queryAppData()
        }
    }
    
    func setOauthQuery(value: String) {
        self.oauthQuery = value
        UserDefaults.standard.set(value, forKey: "oauthQuery")
    }
    
    func logOut() -> Void {
        DispatchQueue.main.async {
            if ((self.activeFile != nil) && self.userFiles.contains(self.activeFile!)) {
                self.setActiveFile(file: self.defaultFiles[0])
            }
            
            self.oauthQuery = ""
            self.userFiles = []
        }
        
        UserDefaults.standard.removeObject(forKey: "userFiles")
        UserDefaults.standard.removeObject(forKey: "oauthQuery")
    }
    
    func setActiveFile(file: APIFile, isUserFile: Bool = false) -> Void {
        DispatchQueue.main.async {
            self.activeFile = file
            
            if (isUserFile) {
                self.getActiveSheetData()
            } else {
                self.queryAppData()
            }
        }
        
        UserDefaults.standard.set(try? PropertyListEncoder().encode(file), forKey:"activeFile")
    }
    
    func refreshList() {
        if (self.activeFile == nil) {
            return
        }
        
        if (self.isUserFile()) {
            self.getActiveSheetData()
        } else {
            self.queryAppData()
        }
    }
    
    func isUserFile() -> Bool {
        guard let activeFile = self.activeFile else {
            return false
        }
        
        if (self.defaultFiles.contains(activeFile)) {
            return false
        }
        
        return true
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
    
    func activeFileUrl() -> URL {
        return URL(string: "Googlesheets://https://docs.google.com/spreadsheets/d/\(self.activeFile!.id)")!
    }
    
    func viewFile(file: APIFile) {
        openURL(URL(string: "https://docs.google.com/spreadsheets/d/\(file.id)")!)
    }
    
    func editFile(file: APIFile) {
        openURL(URL(string: "Googlesheets://https://docs.google.com/spreadsheets/d/\(file.id)")!)
    }
    
    func createSheetUrl(title: String) -> Void {
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        
        let requestUrl = URL(string: "https://api.cyruskrauss.com/sheets/new?title=\(encodedTitle!)&" + self.oauthQuery)
        
        guard let fullRequestUrl = requestUrl else {
            return
        }
        
        self.isCreatingSheet = true
        makeRequest(url: fullRequestUrl) { data in
            // Reload the user's sheets
            self.listUserSheets()
        }
    }
    
    func listUserSheets() -> Void {
        let requestUrl = URL(string: "https://api.cyruskrauss.com/sheets?" + self.oauthQuery)!
        
        makeRequest(url: requestUrl) { data in
            do {
                let result = try JSONDecoder().decode(APIListFilesResponse.self, from: data)
                DispatchQueue.main.async {
                    self.userFiles = result.files
                }
                
                UserDefaults.standard.set(try? PropertyListEncoder().encode(result.files), forKey:"userFiles")
            } catch let responseError {
                DispatchQueue.main.async {
                    self.userFiles = []
                }
                
                UserDefaults.standard.removeObject(forKey: "userFiles")
                print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
            }
            
            self.isCreatingSheet = false
        }
    }
    
    func listDefaultSheets() -> Void {
        let requestUrl = URL(string: "https://api.cyruskrauss.com/sheets/default")!
        
        makeRequest(url: requestUrl) { data in
            do {
                let result = try JSONDecoder().decode([APIFile].self, from: data)
                
                DispatchQueue.main.async {
                    self.defaultFiles = result
                    
                    if (self.activeFile == nil && !result.isEmpty) {
                        self.setActiveFile(file: result.first!)
                    }
                }
                
                UserDefaults.standard.set(try? PropertyListEncoder().encode(result), forKey:"defaultFiles")
            } catch let responseError {
                print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
            }
        }
    }
    
    func getActiveSheetData() -> Void {
        guard let activeSheet = self.activeFile else {
            return
        }
                
        let requestUrl = URL(string: "https://api.cyruskrauss.com/sheets/\(activeSheet.id)?" + self.oauthQuery)!
        
        // TODO: Update this route
        makeRequest(url: requestUrl) { data in
            do {
                let result = try JSONDecoder().decode(APIGetSheetResponse.self, from: data)
                let categories = self.oauthDataAdapter.processData(rows: result.values)
                self.parseAppData(categories: categories)
            } catch let responseError {
                print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
            }
        }
    }
  
    func setCategories(newCategories: [AppCategory]) {
        // Publish the categories so the main thread and view will trigger UI updates
        DispatchQueue.main.async {
            self.categories = newCategories
        }
    }

    func queryAppData() -> Void {
        guard let file = self.activeFile else {
            return
        }
        
        let requestUrl = URL(string: dataAdapter.getDataUrl(sheetId: file.id))!
        
        makeRequest(url: requestUrl) { data in
            // Convert HTTP Response Data to a simple String
            if let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
                let categories = self.dataAdapter.parseCategories(data: dataString)
                self.parseAppData(categories: categories)
            }
        }
    }
    
    func parseAppData(categories: [AppCategory]) {

        // Sort the categories by name
        let sortedCategories = categories.sorted { $0.name < $1.name }
        
        setCategories(newCategories: sortedCategories)
        
        // Save the categories in UserDefaults
        UserDefaults.standard.set(try? PropertyListEncoder().encode(sortedCategories), forKey:"categories")
    }
    
    private func deserializeStoredValueAs<T: Decodable>(key: String, type: T.Type) -> T? {
        if let data = UserDefaults.standard.value(forKey: key) as? Data {
            let decodedValue = try? PropertyListDecoder().decode(type, from: data)

            return decodedValue
        }
        
        return nil;
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
