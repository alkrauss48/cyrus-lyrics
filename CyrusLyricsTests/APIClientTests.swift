//
//  APIClientTests.swift
//  CyrusLyricsTests
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation
import Testing
@testable import CyrusLyrics

struct APIClientTests {
    @Test func sendsTheTokenToTheBackend() async throws {
        let environment = TestEnvironment { _ in (200, listFilesResponse([])) }

        _ = try await environment.api.listUserFiles(token: "secret")

        let request = try #require(environment.log.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        #expect(request.url?.path == "/sheets")
    }

    @Test func neverSendsAnAuthorizationHeaderToGoogle() async throws {
        let environment = TestEnvironment { _ in (200, gvizResponse(rows: [headerRow])) }
        let file = APIFile(id: environment.sheetID, name: "Demo Songs")

        _ = try await environment.api.publicSheet(file)

        let request = try #require(environment.log.requests.first)
        #expect(request.url?.host == "docs.google.com")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func percentEncodesTheNewSheetTitle() async throws {
        let environment = TestEnvironment { _ in (200, Data()) }

        try await environment.api.createSheet(title: "Rock & Roll + More", token: "secret")

        let request = try #require(environment.log.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.query == "title=Rock%20%26%20Roll%20%2B%20More")
    }

    @Test func treatsAMissingValuesKeyAsAnEmptySheet() async throws {
        let environment = TestEnvironment { _ in (200, Data(#"{"range":"Sheet1","majorDimension":"ROWS"}"#.utf8)) }

        let values = try await environment.api.sheetValues(id: "abc", token: "secret")

        #expect(values.isEmpty)
    }

    @Test func throwsHTTPErrorsWithTheirStatusCode() async {
        let environment = TestEnvironment { _ in (503, Data()) }

        let error = await #expect(throws: RequestError.self) {
            try await environment.api.listDefaultFiles()
        }

        guard case .http(statusCode: 503)? = error else {
            Issue.record("Expected an HTTP 503 error, got \(String(describing: error))")
            return
        }
    }

    @Test func throwsDecodingErrorsForUnexpectedBodies() async {
        let environment = TestEnvironment { _ in (200, Data("<html>".utf8)) }

        let error = await #expect(throws: RequestError.self) {
            try await environment.api.listUserFiles(token: "secret")
        }

        guard case .decoding? = error else {
            Issue.record("Expected a decoding error, got \(String(describing: error))")
            return
        }
    }

    @Test(arguments: [
        (RequestError.http(statusCode: 400), true),
        (RequestError.http(statusCode: 401), true),
        (RequestError.http(statusCode: 404), true),
        (RequestError.http(statusCode: 500), false),
        (RequestError.http(statusCode: 503), false),
        (RequestError.transport(URLError(.notConnectedToInternet)), false),
        (RequestError.decoding(URLError(.cannotParseResponse)), true),
    ])
    func decidesWhichErrorsSignTheUserOut(error: RequestError, signsOut: Bool) {
        #expect(error.invalidatesSession == signsOut)
    }
}
