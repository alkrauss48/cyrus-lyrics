//
//  TestSupport.swift
//  CyrusLyricsTests
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation
@testable import CyrusLyrics

/// Serves canned responses to requests made through `StubURLProtocol.session`.
///
/// Each test registers a handler under a unique key and puts that key in the
/// URLs it requests (in the backend host or a sheet ID), so tests can run in
/// parallel without seeing each other's requests.
final class StubURLProtocol: URLProtocol {
    typealias Handler = @Sendable (URLRequest) throws -> (statusCode: Int, body: Data)

    static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    private static let lock = NSLock()
    nonisolated(unsafe) private static var handlers: [String: Handler] = [:]

    static func register(_ key: String, handler: @escaping Handler) {
        lock.withLock { handlers[key] = handler }
    }

    static func unregister(_ key: String) {
        lock.withLock { handlers[key] = nil }
    }

    private static func handler(for url: URL) -> Handler? {
        lock.withLock {
            handlers.first { url.absoluteString.contains($0.key) }?.value
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let handler = Self.handler(for: url) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        do {
            let (statusCode, body) = try handler(request)
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// Records requests so tests can check what was sent.
final class RequestLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [URLRequest] = []

    func append(_ request: URLRequest) {
        lock.withLock { storage.append(request) }
    }

    var requests: [URLRequest] {
        lock.withLock { storage }
    }
}

/// An isolated set of dependencies for one test: its own UserDefaults suite,
/// Keychain service, and stubbed backend.
final class TestEnvironment {
    let key = "test-\(UUID().uuidString.lowercased())"
    let defaults: UserDefaults
    let store: LocalStore
    let tokenStore: TokenStore
    let api: APIClient
    let log = RequestLog()

    init(handler: @escaping @Sendable (URLRequest) throws -> (statusCode: Int, body: Data) = { _ in (404, Data()) }) {
        defaults = UserDefaults(suiteName: key)!
        store = LocalStore(defaults: defaults)
        tokenStore = TokenStore(service: key)
        api = APIClient(baseURL: URL(string: "https://\(key).example.com")!, session: StubURLProtocol.session)

        // Act like an existing install, not a fresh one
        store.set(true, for: .hasLaunched)

        let log = log
        StubURLProtocol.register(key) { request in
            log.append(request)
            return try handler(request)
        }
    }

    /// A sheet ID that routes Google requests to this environment's handler.
    var sheetID: String {
        "\(key)-sheet"
    }

    @MainActor
    func makeStateManager() -> StateManager {
        StateManager(api: api, store: store, tokenStore: tokenStore)
    }

    deinit {
        StubURLProtocol.unregister(key)
        defaults.removePersistentDomain(forName: key)
        tokenStore.delete()
    }
}

func json(_ value: some Encodable) -> Data {
    try! JSONEncoder().encode(value)
}

/// A `GET /sheets` response body.
func listFilesResponse(_ files: [APIFile]) -> Data {
    json(["files": files])
}

/// A response in the format Google's public "gviz" endpoint uses.
func gvizResponse(rows: [[String?]]) -> Data {
    let rowsJSON = rows.map { row in
        let cells = row.map { cell in
            cell.map { #"{"v":\#(String(data: json($0), encoding: .utf8)!)}"# } ?? "null"
        }
        return #"{"c":[\#(cells.joined(separator: ","))]}"#
    }

    return Data("""
    /*O_o*/
    google.visualization.Query.setResponse({"version":"0.6","reqId":"0","status":"ok","table":{"cols":[],"rows":[\(rowsJSON.joined(separator: ","))]}});
    """.utf8)
}

let headerRow: [String?] = ["Category", "Subcategory", "Name", "URL", "Lyrics", "Spotify URL"]
