//
//  APIClient.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation
import OSLog

enum RequestError: Error {
    case transport(any Error)
    case http(statusCode: Int)
    case decoding(any Error)

    /// The backend sends a 4xx when the token is invalid or the sheet is
    /// gone, and it can send a 2xx with an unexpected body when the token has
    /// expired. Both mean the user needs to sign in again. Network problems
    /// and 5xx responses are treated as temporary.
    var invalidatesSession: Bool {
        switch self {
        case .http(let statusCode):
            return (400..<500).contains(statusCode)
        case .decoding:
            return true
        case .transport:
            return false
        }
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

/// Talks to the CyrusLyrics backend and to Google's public sheet endpoint.
struct APIClient: Sendable {
    /// For local backend development, pass a tunnel URL (like an ngrok URL)
    /// as `baseURL` instead. Never commit a non-production URL.
    static let productionBaseURL = URL(string: "https://api.cyruskrauss.com")!

    let baseURL: URL
    let session: URLSession

    init(baseURL: URL = APIClient.productionBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Starts Google sign-in. When it's done, the backend redirects to
    /// `cyruslyrics://...?token=<token>`.
    var signInURL: URL {
        baseURL.appending(path: "oauth/google")
    }

    func listDefaultFiles() async throws(RequestError) -> [APIFile] {
        try decode([APIFile].self, from: await send("GET", "sheets/default"))
    }

    func listUserFiles(token: String) async throws(RequestError) -> [APIFile] {
        try decode(APIListFilesResponse.self, from: await send("GET", "sheets", token: token)).files
    }

    func sheetValues(id: String, token: String) async throws(RequestError) -> [[String]] {
        try decode(APIGetSheetResponse.self, from: await send("GET", "sheets/\(id)", token: token)).values ?? []
    }

    func createSheet(title: String, token: String) async throws(RequestError) {
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        _ = try await send("POST", "sheets", query: "title=\(encodedTitle)", token: token)
    }

    func deleteSheet(id: String, token: String) async throws(RequestError) {
        _ = try await send("DELETE", "sheets/\(id)", token: token)
    }

    /// The raw response from Google's public endpoint for a preloaded list.
    func publicSheet(_ file: APIFile) async throws(RequestError) -> String {
        guard let url = file.publicDataURL else {
            throw .transport(URLError(.badURL))
        }

        // This goes to Google, so it never includes the token.
        let data = try await data(for: URLRequest(url: url))
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Requests

    /// Sends a request to the backend. This is the only place the token is
    /// attached, so it's never sent to third parties.
    private func send(_ method: String, _ path: String, query: String? = nil, token: String? = nil) async throws(RequestError) -> Data {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = query

        guard let url = components?.url else {
            throw .transport(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return try await data(for: request)
    }

    private func data(for request: URLRequest) async throws(RequestError) -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            Logger.network.error("Request to \(request.url?.path ?? "", privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            throw .transport(error)
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            Logger.network.error("Request to \(request.url?.path ?? "", privacy: .public) failed with status \(httpResponse.statusCode)")
            throw .http(statusCode: httpResponse.statusCode)
        }

        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws(RequestError) -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            Logger.network.error("Couldn't decode \(String(describing: type), privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw .decoding(error)
        }
    }
}
