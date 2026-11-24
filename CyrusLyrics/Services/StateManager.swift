//
//  StateManager.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import Foundation
import Network
import SwiftUI

enum RequestError: Error {
    case transport(Error)
    case noData
    case http(statusCode: Int)

    /// Client errors (4xx) mean the token is invalid or the resource is gone,
    /// so the app treats them like an auth failure. Server errors (5xx) and
    /// network problems are treated as transient.
    var isClientError: Bool {
        if case .http(let statusCode) = self {
            return (400..<500).contains(statusCode)
        }

        return false
    }

    var isUnauthorized: Bool {
        if case .http(let statusCode) = self {
            return statusCode == 401 || statusCode == 403
        }

        return false
    }

    var isNotFound: Bool {
        if case .http(let statusCode) = self {
            return statusCode == 404
        }

        return false
    }
}

class StateManager: ObservableObject {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")
    @Published private(set) var connected: Bool = false
    
    @Published var menuOpen: Bool = false
    @Published var rootView: String = StateManager.SET_DATA_VIEW
    @Published var oauthToken: String = ""
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
//    static var BASE_API_URL = "https://ccf2-72-211-8-17.ngrok.io"

    static var stateManager = StateManager()
    
    static func Get() -> StateManager {
        return self.stateManager
    }
    
    init() {
        checkConnection()
        
        if let value = UserDefaults.standard.string(forKey: "oauthQuery") {
            self.oauthToken = value
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
        self.oauthToken = value
        UserDefaults.standard.set(value, forKey: "oauthQuery")
    }
    
    func logOut() -> Void {
        DispatchQueue.main.async {
            if let activeFile = self.activeFile, self.userFiles.contains(activeFile) {
                self.resetActiveFileToDefault()
            }
            
            self.oauthToken = ""
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
    
    /// Switch to the first preloaded list, or clear the active list if the
    /// preloaded lists haven't loaded yet (e.g. first launch while offline).
    private func resetActiveFileToDefault() {
        if let defaultFile = self.defaultFiles.first {
            self.setActiveFile(file: defaultFile)
            return
        }

        self.activeFile = nil
        self.categories = []
        UserDefaults.standard.removeObject(forKey: "activeFile")
        UserDefaults.standard.removeObject(forKey: "categories")
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
        return !self.oauthToken.isEmpty
    }
    
    func authUrl() -> URL {
        return URL(string: StateManager.BASE_API_URL + "/oauth/google")!
    }
    
    func activeFileUrl() -> URL {
        guard let activeFile = self.activeFile else {
            return URL(string: "googlesheets://")!
        }

        return sheetsAppUrl(for: activeFile)
    }
    
    private func sheetsAppUrl(for file: APIFile) -> URL {
        return URL(string: "Googlesheets://https://docs.google.com/spreadsheets/d/\(file.id)")!
    }
    
    func viewFile(file: APIFile) {
        UIApplication.shared.open(URL(string: "https://docs.google.com/spreadsheets/d/\(file.id)")!)
    }
    
    func editFile(file: APIFile) {
        UIApplication.shared.open(sheetsAppUrl(for: file))
    }
    
    func createSheetUrl(title: String) -> Void {
        guard let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets?title=\(encodedTitle)") else {
            return
        }
        
        self.isCreatingSheet = true
        makeRequest(url: requestUrl, method: "POST") { result in
            switch result {
            case .success:
                // Reload the user's sheets, which also clears isCreatingSheet
                self.listUserSheets()
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isCreatingSheet = false
                }

                if error.isUnauthorized {
                    self.logOut()
                }
            }
        }
    }

    func deleteFile(file: APIFile) -> Void {
        let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets/\(file.id)")!
        
        self.isDeletingSheet = file
        makeRequest(url: requestUrl, method: "DELETE") { result in
            DispatchQueue.main.async {
                self.isDeletingSheet = nil

                if case .failure(let error) = result, !error.isNotFound {
                    if error.isUnauthorized {
                        self.logOut()
                    }

                    return
                }

                // Deleted, or already gone (404)
                self.userFiles.removeAll { $0.id == file.id }
                if (self.activeFile?.id == file.id) {
                    self.resetActiveFileToDefault()
                }
                UserDefaults.standard.set(try? PropertyListEncoder().encode(self.userFiles), forKey:"userFiles")
            }
        }
    }
    
    func listUserSheets() -> Void {
        let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets")!
        
        makeRequest(url: requestUrl, method: "GET") { result in
            defer {
                DispatchQueue.main.async {
                    self.isCreatingSheet = false
                }
            }

            switch result {
            case .success(let data):
                do {
                    let result = try JSONDecoder().decode(APIListFilesResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.userFiles = result.files.sorted { $0.name < $1.name }
                    }
                    
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(result.files), forKey:"userFiles")
                } catch let responseError {
                    // A successful response we can't decode means the token is no longer valid
                    print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
                    self.logOut()
                }
            case .failure(let error):
                // Keep the cached lists on network or server errors
                if error.isClientError {
                    self.logOut()
                }
            }
        }
    }
    
    func listDefaultSheets() -> Void {
        let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets/default")!
        
        makeRequest(url: requestUrl, method: "GET") { result in
            guard case .success(let data) = result else {
                return
            }

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
                
        let requestUrl = URL(string: StateManager.BASE_API_URL + "/sheets/\(activeSheet.id)")!
        
        makeRequest(url: requestUrl, method: "GET") { result in
            defer {
                DispatchQueue.main.async {
                    self.isLoadingFile = false
                }
            }

            switch result {
            case .success(let data):
                do {
                    let result = try JSONDecoder().decode(APIGetSheetResponse.self, from: data)
                    let categories = self.oauthDataAdapter.processData(rows: result.values)
                    self.parseAppData(categories: categories)
                } catch let responseError {
                    // A successful response we can't decode means the token is no longer valid
                    print("Serialisation in error in creating response body: \(responseError.localizedDescription)")
                    self.logOut()
                }
            case .failure(let error):
                // Keep the cached categories on network or server errors
                if error.isClientError {
                    self.logOut()
                }
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
        
        makeRequest(url: requestUrl, method: "GET") { result in
            // Convert HTTP Response Data to a simple String. If the response
            // can't be parsed, keep the cached categories for offline use.
            if case .success(let data) = result,
               let dataString = String(data: data, encoding: .utf8),
               let categories = self.dataAdapter.parseCategories(data: dataString) {
                self.parseAppData(categories: categories)
            }
            
            DispatchQueue.main.async {
                self.isLoadingFile = false
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
    
    private func makeRequest(url: URL, method: String, callback: @escaping (Result<Data, RequestError>) -> ()) {
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Only send the token to our own backend, not to third parties like Google
        if url.host == URL(string: StateManager.BASE_API_URL)?.host {
            request.setValue("Bearer " + self.oauthToken, forHTTPHeaderField: "Authorization")
        }
        
        // Create the session object
        let session = URLSession.shared
        
        // Create a task using the session object, to run and return completion handler
        let webTask = session.dataTask(with: request) {data, response, error in
            if let error = error {
                print(error.localizedDescription)
                callback(.failure(.transport(error)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                print("Request to \(url.path) failed with status \(httpResponse.statusCode)")
                callback(.failure(.http(statusCode: httpResponse.statusCode)))
                return
            }

            guard let serverData = data else {
                print("server data error")
                callback(.failure(.noData))
                return
            }
            
            callback(.success(serverData))
        }

        // Run the task
        webTask.resume()
    }
}
