//
//  StateManager.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import Foundation
import Network
import SwiftUI

class StateManager: ObservableObject {
    @Environment(\.openURL) var openURL

    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")
    @Published private(set) var connected: Bool = false
    
    @Published var menuOpen: Bool = false
    @Published var rootView: String = StateManager.SET_DATA_VIEW
    @Published var oauthQuery: String = ""
    @Published var userFiles: [APIFile] = []
    @Published var defaultFiles: [APIFile] = []
    @Published var categories = [AppCategory]()
    @Published var activeFile: APIFile?
    @Published var isCreatingSheet: Bool = false
    @Published var isDeletingSheet: APIFile?
    @Published var showLoginActionSheet = false
    @Published var isLoadingFile: Bool = false
    
    var dataAdapter = SheetsV2Adapter()
    var oauthDataAdapter = OAuthSheetAdapter()
    
    static var CATEGORY_LIST_VIEW = "CATEGORY_LIST_VIEW"
    static var SET_DATA_VIEW = "SET_DATA_VIEW"
    static var HOW_IT_WORKS_VIEW = "HOW_IT_WORKS_VIEW"
    
    static var BASE_API_URL = "https://api.cyruskrauss.com"
//    static var BASE_API_URL = "https://a652-72-211-8-17.ngrok.io"

    static var stateManager = StateManager()
    
    static func Get() -> StateManager {
        return self.stateManager
    }
    
    init() {
        checkConnection()
        
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
        
        // Load up app categories
        if let categories = deserializeStoredValueAs(key: "categories", type: [AppCategory].self) {
            setCategories(newCategories: categories)
        }
        
        // Load up the active file
        if let storedActiveFile = deserializeStoredValueAs(key: "activeFile", type: APIFile.self) {
            setActiveFile(file: storedActiveFile)
        }
    }
    
    func checkConnection() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.connected = path.status == .satisfied ? true : false
            }
        }
        monitor.start(queue: queue)
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
    
    func setActiveFile(file: APIFile) -> Void {
        if (self.activeFile != file) {
            self.isLoadingFile = true;
        }
        
        self.activeFile = file
        
        if (self.isUserFile()) {
            self.getActiveSheetData()
        } else {
            self.queryAppData()
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
        return URL(string: StateManager.BASE_API_URL + "/oauth/google")!
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
        
        let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets?title=\(encodedTitle!)&" + self.oauthQuery)
        
        guard let fullRequestUrl = requestUrl else {
            return
        }
        
        self.isCreatingSheet = true
        makeRequest(url: fullRequestUrl, method: "POST") { data in
            // Reload the user's sheets
            self.listUserSheets()
        }
    }

    func deleteFile(file: APIFile) -> Void {
        let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets/\(file.id)?" + self.oauthQuery)!
        
        self.isDeletingSheet = file
        makeRequest(url: requestUrl, method: "DELETE") { data in
            guard let index = (self.userFiles.firstIndex{ $0.id == file.id }) else {
                return
            }
            
            DispatchQueue.main.async {
                self.userFiles.remove(at: index)
                if (self.activeFile != nil && self.activeFile!.id == file.id) {
                    self.setActiveFile(file: self.defaultFiles[0])
                }
                self.isDeletingSheet = nil
                UserDefaults.standard.set(try? PropertyListEncoder().encode(self.userFiles), forKey:"userFiles")
            }
        }
    }
    
    func listUserSheets() -> Void {
        let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets?" + self.oauthQuery)!
        
        makeRequest(url: requestUrl, method: "GET") { data in
            do {
                let result = try JSONDecoder().decode(APIListFilesResponse.self, from: data)
                DispatchQueue.main.async {
                    self.userFiles = result.files.sorted { $0.name < $1.name }
                    self.isCreatingSheet = false
                }
                
                UserDefaults.standard.set(try? PropertyListEncoder().encode(result.files), forKey:"userFiles")
            } catch let responseError {
                DispatchQueue.main.async {
                    self.userFiles = []
                    self.isCreatingSheet = false

                }
                
                UserDefaults.standard.removeObject(forKey: "userFiles")
                print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
            }
        }
    }
    
    func listDefaultSheets() -> Void {
        let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets/default")!
        
        makeRequest(url: requestUrl, method: "GET") { data in
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
                
        let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets/\(activeSheet.id)?" + self.oauthQuery)!
        
        // TODO: Update this route
        makeRequest(url: requestUrl, method: "GET") { data in
            do {
                let result = try JSONDecoder().decode(APIGetSheetResponse.self, from: data)
                let categories = self.oauthDataAdapter.processData(rows: result.values)
                self.parseAppData(categories: categories)
            } catch let responseError {
                print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
            }
            
            self.isLoadingFile = false
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
        
        makeRequest(url: requestUrl, method: "GET") { data in
            // Convert HTTP Response Data to a simple String
            if let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
                let categories = self.dataAdapter.parseCategories(data: dataString)
                self.parseAppData(categories: categories)
            }
            
            self.isLoadingFile = false
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
    
    private func makeRequest(url: URL, method: String, callback: @escaping (Data) -> ()) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
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
