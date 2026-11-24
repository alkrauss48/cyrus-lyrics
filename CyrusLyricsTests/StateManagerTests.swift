//
//  StateManagerTests.swift
//  CyrusLyricsTests
//
//  Created by Aaron Krauss on 11/24/26.
//

import Foundation
import Testing
@testable import CyrusLyrics

@MainActor
struct StateManagerTests {
    // MARK: - Token storage

    @Test func movesTheLegacyTokenToTheKeychain() {
        let environment = TestEnvironment()
        environment.defaults.set("legacy-token", forKey: "oauthQuery")

        let stateManager = environment.makeStateManager()

        #expect(stateManager.isLoggedIn)
        #expect(environment.tokenStore.load() == "legacy-token")
        #expect(environment.defaults.string(forKey: "oauthQuery") == nil)
    }

    @Test func clearsATokenLeftOverFromAPreviousInstall() {
        let environment = TestEnvironment()
        environment.store.remove(.hasLaunched)
        environment.tokenStore.save("old-install-token")

        let stateManager = environment.makeStateManager()

        #expect(!stateManager.isLoggedIn)
        #expect(environment.tokenStore.load() == nil)
    }

    @Test func loadsCachedDataOnLaunch() {
        let environment = TestEnvironment()
        let file = APIFile(id: "abc", name: "Demo Songs")
        environment.store.save([file], for: .defaultFiles)
        environment.store.save(file, for: .activeFile)
        environment.store.save(SheetParser.categories(fromRows: [headerRow, ["Country", "Darius Rucker", "Wagon Wheel"]]), for: .categories)

        let stateManager = environment.makeStateManager()

        #expect(stateManager.defaultFiles == [file])
        #expect(stateManager.activeFile == file)
        #expect(stateManager.categories.links(in: .all).map(\.name) == ["Wagon Wheel"])
    }

    // MARK: - Sign-in

    @Test func signInStoresTheTokenAndLoadsTheUsersLists() async {
        let userFile = APIFile(id: "mine", name: "My Songs")
        let environment = TestEnvironment { _ in (200, listFilesResponse([userFile])) }
        let stateManager = environment.makeStateManager()

        await stateManager.signIn(callbackURL: URL(string: "cyruslyrics://login?token=abc123&access_token=x")!)

        #expect(stateManager.isLoggedIn)
        #expect(environment.tokenStore.load() == "abc123")
        #expect(stateManager.userFiles == [userFile])
    }

    @Test func signInIgnoresCallbacksWithoutAToken() async {
        let environment = TestEnvironment()
        let stateManager = environment.makeStateManager()

        await stateManager.signIn(callbackURL: URL(string: "cyruslyrics://login")!)

        #expect(!stateManager.isLoggedIn)
        #expect(environment.log.requests.isEmpty)
    }

    @Test(arguments: [401, 403, 400])
    func signsOutWhenTheBackendRejectsTheToken(statusCode: Int) async {
        let environment = TestEnvironment { _ in (statusCode, Data()) }
        environment.tokenStore.save("expired")
        environment.store.save([APIFile(id: "mine", name: "My Songs")], for: .userFiles)
        let stateManager = environment.makeStateManager()
        #expect(stateManager.userFiles.count == 1)

        await stateManager.refreshLists()

        #expect(!stateManager.isLoggedIn)
        #expect(stateManager.userFiles.isEmpty)
        #expect(environment.tokenStore.load() == nil)
        #expect(environment.store.load([APIFile].self, for: .userFiles) == nil)
    }

    @Test(arguments: [500, 503])
    func keepsTheSessionAndCacheOnServerErrors(statusCode: Int) async {
        let environment = TestEnvironment { _ in (statusCode, Data()) }
        let defaultFile = APIFile(id: "default", name: "Demo Songs")
        let userFile = APIFile(id: "mine", name: "My Songs")
        environment.tokenStore.save("valid")
        environment.store.save([defaultFile], for: .defaultFiles)
        environment.store.save([userFile], for: .userFiles)
        let stateManager = environment.makeStateManager()

        await stateManager.refreshLists()

        #expect(stateManager.isLoggedIn)
        #expect(stateManager.defaultFiles == [defaultFile])
        #expect(stateManager.userFiles == [userFile])
    }

    @Test func signingOutOnAUserListSwitchesToAPreloadedList() async {
        let environment = TestEnvironment()
        let defaultFile = APIFile(id: environment.sheetID, name: "Demo Songs")
        let userFile = APIFile(id: "mine", name: "My Songs")
        environment.tokenStore.save("valid")
        environment.store.save([defaultFile], for: .defaultFiles)
        environment.store.save([userFile], for: .userFiles)
        environment.store.save(userFile, for: .activeFile)
        let stateManager = environment.makeStateManager()
        #expect(stateManager.isUserFile)

        stateManager.signOut()

        #expect(stateManager.activeFile == defaultFile)
        #expect(!stateManager.isUserFile)
    }

    // MARK: - Loading lists

    @Test func loadsAPreloadedListFromGoogle() async {
        let environment = TestEnvironment { _ in
            (200, gvizResponse(rows: [headerRow, ["Country", "Darius Rucker", "Wagon Wheel"]]))
        }
        let file = APIFile(id: environment.sheetID, name: "Demo Songs")
        environment.store.save([file], for: .defaultFiles)
        let stateManager = environment.makeStateManager()

        stateManager.open(file)
        #expect(stateManager.isLoadingFile)
        await stateManager.refreshActiveFile()

        #expect(!stateManager.isLoadingFile)
        #expect(stateManager.categories.links(in: .all).map(\.name) == ["Wagon Wheel"])
        #expect(environment.store.load([AppCategory].self, for: .categories) == stateManager.categories)
        #expect(environment.store.load(APIFile.self, for: .activeFile) == file)
    }

    @Test func loadsAUserListFromTheBackend() async throws {
        let environment = TestEnvironment { _ in
            (200, Data(#"{"values":[["Genre","Artist","Song Title"],["Country","Darius Rucker","Wagon Wheel"]]}"#.utf8))
        }
        let userFile = APIFile(id: "mine", name: "My Songs")
        environment.tokenStore.save("valid")
        environment.store.save([userFile], for: .userFiles)
        let stateManager = environment.makeStateManager()

        stateManager.open(userFile)
        await stateManager.refreshActiveFile()

        #expect(stateManager.categories.links(in: .all).map(\.name) == ["Wagon Wheel"])
        let request = try #require(environment.log.requests.last)
        #expect(request.url?.path == "/sheets/mine")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer valid")
    }

    @Test func keepsCachedSongsWhenTheListFailsToLoad() async {
        let environment = TestEnvironment { _ in (200, Data("<html>Not a sheet</html>".utf8)) }
        let file = APIFile(id: environment.sheetID, name: "Demo Songs")
        let cached = SheetParser.categories(fromRows: [headerRow, ["Country", "Darius Rucker", "Wagon Wheel"]])
        environment.store.save([file], for: .defaultFiles)
        environment.store.save(file, for: .activeFile)
        environment.store.save(cached, for: .categories)
        let stateManager = environment.makeStateManager()

        await stateManager.refreshActiveFile()

        #expect(stateManager.categories == cached)
        #expect(environment.store.load([AppCategory].self, for: .categories) == cached)
    }

    @Test func switchingListsClearsThePreviousListsSongs() {
        let environment = TestEnvironment()
        let first = APIFile(id: "first", name: "First")
        let second = APIFile(id: environment.sheetID, name: "Second")
        environment.store.save([first, second], for: .defaultFiles)
        environment.store.save(first, for: .activeFile)
        environment.store.save(SheetParser.categories(fromRows: [headerRow, ["Country", "Darius Rucker", "Wagon Wheel"]]), for: .categories)
        let stateManager = environment.makeStateManager()

        stateManager.open(second)

        #expect(stateManager.activeFile == second)
        #expect(stateManager.categories.isEmpty)
        #expect(environment.store.load([AppCategory].self, for: .categories) == nil)
    }

    // MARK: - Deleting lists

    @Test func deletingTheActiveListSwitchesToAPreloadedList() async {
        let environment = TestEnvironment { _ in (200, Data()) }
        let defaultFile = APIFile(id: environment.sheetID, name: "Demo Songs")
        let userFile = APIFile(id: "mine", name: "My Songs")
        environment.tokenStore.save("valid")
        environment.store.save([defaultFile], for: .defaultFiles)
        environment.store.save([userFile], for: .userFiles)
        environment.store.save(userFile, for: .activeFile)
        let stateManager = environment.makeStateManager()

        await stateManager.delete(userFile)

        #expect(stateManager.userFiles.isEmpty)
        #expect(stateManager.activeFile == defaultFile)
        #expect(stateManager.deletingFile == nil)
        #expect(environment.store.load([APIFile].self, for: .userFiles) == [])
    }

    @Test func deletingAListThatsAlreadyGoneRemovesIt() async {
        let environment = TestEnvironment { _ in (404, Data()) }
        let userFile = APIFile(id: "mine", name: "My Songs")
        environment.tokenStore.save("valid")
        environment.store.save([userFile], for: .userFiles)
        let stateManager = environment.makeStateManager()

        await stateManager.delete(userFile)

        #expect(stateManager.userFiles.isEmpty)
        #expect(stateManager.isLoggedIn)
    }

    @Test func failedDeleteKeepsTheList() async {
        let environment = TestEnvironment { _ in (500, Data()) }
        let userFile = APIFile(id: "mine", name: "My Songs")
        environment.tokenStore.save("valid")
        environment.store.save([userFile], for: .userFiles)
        let stateManager = environment.makeStateManager()

        await stateManager.delete(userFile)

        #expect(stateManager.userFiles == [userFile])
        #expect(stateManager.isLoggedIn)
        #expect(stateManager.deletingFile == nil)
    }

    @Test func creatingAListReloadsTheUsersLists() async throws {
        let newFile = APIFile(id: "new", name: "Rock & Roll")
        let environment = TestEnvironment { request in
            request.httpMethod == "POST" ? (200, Data()) : (200, listFilesResponse([newFile]))
        }
        environment.tokenStore.save("valid")
        let stateManager = environment.makeStateManager()

        await stateManager.createSheet(title: "Rock & Roll")

        #expect(stateManager.userFiles == [newFile])
        #expect(!stateManager.isCreatingSheet)
        #expect(environment.log.requests.map(\.httpMethod) == ["POST", "GET"])
    }
}
