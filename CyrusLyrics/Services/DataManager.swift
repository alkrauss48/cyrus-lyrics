//
//  LoadData.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

// Spreadsheet JSONifying based on: https://www.freecodecamp.org/news/cjn-google-sheets-as-json-endpoint/
// HTTP Request logic based on: https://www.appsdeveloperblog.com/http-get-request-example-in-swift/

import Foundation
import Combine
import SwiftUI

class DataManager: ObservableObject {
    @Published var categories = [AppCategory]()
    var dataAdapter = SheetsV2Adapter()
  
    init() {
        if let data = UserDefaults.standard.value(forKey:"categories") as? Data {
            loadAppData(data: data)
        } else {
            queryAppData()
        }
    }
    
    func loadAppData(data: Data) {
        let existingCategories = try? PropertyListDecoder().decode(Array<AppCategory>.self, from: data)
        
        if (existingCategories == nil) {
            queryAppData()
            return
        }
        
        setCategories(newCategories: existingCategories!)
    }
  
    func setCategories(newCategories: [AppCategory]) {
        // Publish the categories so the main thread and view will trigger UI updates
        DispatchQueue.main.async {
            self.categories = newCategories
        }
    }

    func queryAppData() -> Void {
        // Create URL
        let url = URL(string: dataAdapter.dataUrl)
        guard let requestUrl = url else { fatalError() }

        // Create URL Request
        var request = URLRequest(url: requestUrl)

        // Specify HTTP Method to use
        request.httpMethod = "GET"

        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            // Check if Error took place
            if let error = error {
                print("Error took place \(error)")
                return
            }

            // Read HTTP Response Status code
            if let response = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(response.statusCode)")
            }

            // Convert HTTP Response Data to a simple String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
                self.parseAppData(data: dataString)
            }

        }

        task.resume()
    }
    
    func parseAppData(data: String!) {
        var tempCategories = dataAdapter.parseCategories(data: data)
        
        // Sort the categories by name
        tempCategories.sort { $0.name < $1.name }
        
        setCategories(newCategories: tempCategories)
        
        // Save the categories in UserDefaults
        UserDefaults.standard.set(try? PropertyListEncoder().encode(tempCategories), forKey:"categories")
    }
}
