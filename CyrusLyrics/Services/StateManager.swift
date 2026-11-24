//
//  StateManager.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import Foundation
import Network
import Observation
import OSLog

/// App-wide state: the available lists, the songs in the active list, and
/// sign-in.
///
/// Everything is cached in `LocalStore`, so the last active list keeps
/// working offline. Network errors and 5xx responses keep the cached data.
/// Responses that mean the token is no longer valid sign the user out.
@MainActor
@Observable
final class StateManager {
    private(set) var isConnected = true
    private(set) var defaultFiles: [APIFile] = []
    private(set) var userFiles: [APIFile] = []
    private(set) var activeFile: APIFile?
    private(set) var categories: [AppCategory] = []
    private(set) var isLoadingFile = false
    private(set) var isCreatingSheet = false
    private(set) var deletingFile: APIFile?
    private var oauthToken: String?

    @ObservationIgnored private let api: APIClient
    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let tokenStore: TokenStore
    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var loadedFileID: APIFile.ID?
    @ObservationIgnored private var hasStarted = false

    init(api: APIClient = APIClient(), store: LocalStore = LocalStore(), tokenStore: TokenStore = TokenStore()) {
        self.api = api
        self.store = store
        self.tokenStore = tokenStore

        migrateToken()
        oauthToken = tokenStore.load()

        defaultFiles = store.load([APIFile].self, for: .defaultFiles) ?? []
        if oauthToken != nil {
            userFiles = store.load([APIFile].self, for: .userFiles) ?? []
        }
        activeFile = store.load(APIFile.self, for: .activeFile)
        categories = store.load([AppCategory].self, for: .categories)?.sortedByName() ?? []
    }

    var isLoggedIn: Bool {
        oauthToken != nil
    }

    var signInURL: URL {
        api.signInURL
    }

    /// Whether the active list belongs to the user, as opposed to being one
    /// of the preloaded lists.
    var isUserFile: Bool {
        guard let activeFile else {
            return false
        }

        return !defaultFiles.contains(activeFile)
    }

    /// Starts watching the network connection and refreshes all data. Safe to
    /// call more than once.
    func start() async {
        guard !hasStarted else {
            return
        }

        hasStarted = true
        startMonitoringConnection()

        if activeFile != nil {
            reloadActiveFile()
        }

        await refreshLists()
    }

    // MARK: - Lists

    func refreshLists() async {
        async let defaultFiles: Void = refreshDefaultFiles()
        async let userFiles: Void = refreshUserFiles()
        _ = await (defaultFiles, userFiles)
    }

    private func refreshDefaultFiles() async {
        do throws(RequestError) {
            let files = try await api.listDefaultFiles()
            defaultFiles = files
            store.save(files, for: .defaultFiles)

            if activeFile == nil, let firstFile = files.first {
                open(firstFile)
            }
        } catch {
            // Keep the cached lists
        }
    }

    private func refreshUserFiles() async {
        guard let token = oauthToken else {
            return
        }

        do throws(RequestError) {
            let files = try await api.listUserFiles(token: token)

            // Ignore the response if the user signed out while it was loading
            guard oauthToken == token else {
                return
            }

            userFiles = files.sorted(byName: \.name)
            store.save(userFiles, for: .userFiles)
        } catch {
            if error.invalidatesSession, oauthToken == token {
                signOut()
            }
        }
    }

    func createSheet(title: String) async {
        guard let token = oauthToken else {
            return
        }

        isCreatingSheet = true
        defer { isCreatingSheet = false }

        do throws(RequestError) {
            try await api.createSheet(title: title, token: token)
            await refreshUserFiles()
        } catch {
            if error.isUnauthorized {
                signOut()
            }
        }
    }

    func delete(_ file: APIFile) async {
        guard let token = oauthToken else {
            return
        }

        deletingFile = file
        defer { deletingFile = nil }

        do throws(RequestError) {
            try await api.deleteSheet(id: file.id, token: token)
        } catch {
            if error.isUnauthorized {
                signOut()
            }

            // A 404 means the sheet is already gone, so remove it below
            guard error.isNotFound else {
                return
            }
        }

        userFiles.removeAll { $0.id == file.id }
        store.save(userFiles, for: .userFiles)

        if activeFile?.id == file.id {
            resetActiveFileToDefault()
        }
    }

    // MARK: - Active list

    /// Makes `file` the active list and loads its songs, unless they've
    /// already loaded since launch. Pull to refresh reloads them.
    func open(_ file: APIFile) {
        if file == activeFile {
            if loadedFileID != file.id && loadTask == nil {
                reloadActiveFile()
            }

            return
        }

        activeFile = file
        store.save(file, for: .activeFile)

        // The cached songs belong to the previous list
        categories = []
        store.remove(.categories)
        loadedFileID = nil
        isLoadingFile = true

        reloadActiveFile()
    }

    /// Reloads the active list's songs and waits until they've loaded.
    func refreshActiveFile() async {
        await reloadActiveFile().value
    }

    @discardableResult
    private func reloadActiveFile() -> Task<Void, Never> {
        loadTask?.cancel()

        let task = Task {
            await loadActiveFile()
        }

        loadTask = task
        return task
    }

    private func loadActiveFile() async {
        guard let file = activeFile else {
            isLoadingFile = false
            return
        }

        defer {
            // If a newer load replaced this one, that load owns these
            if !Task.isCancelled {
                isLoadingFile = false
                loadTask = nil
            }
        }

        let rows: [[String?]]

        if isUserFile {
            guard let token = oauthToken else {
                return
            }

            do throws(RequestError) {
                rows = SheetParser.rows(fromAPIValues: try await api.sheetValues(id: file.id, token: token))
            } catch {
                if !Task.isCancelled, error.invalidatesSession, oauthToken == token {
                    signOut()
                }

                return
            }
        } else {
            do throws(RequestError) {
                let response = try await api.publicSheet(file)

                guard let parsedRows = SheetParser.rows(fromGvizResponse: response) else {
                    Logger.network.error("Unexpected response format for \(file.id, privacy: .public)")
                    return
                }

                rows = parsedRows
            } catch {
                return
            }
        }

        guard !Task.isCancelled, activeFile == file else {
            return
        }

        categories = SheetParser.categories(fromRows: rows)
        loadedFileID = file.id
        store.save(categories, for: .categories)
    }

    /// Switches to the first preloaded list, or clears the active list if the
    /// preloaded lists haven't loaded yet (for example, on a first launch
    /// while offline).
    private func resetActiveFileToDefault() {
        if let defaultFile = defaultFiles.first {
            open(defaultFile)
            return
        }

        loadTask?.cancel()
        loadTask = nil
        activeFile = nil
        categories = []
        loadedFileID = nil
        isLoadingFile = false
        store.remove(.activeFile)
        store.remove(.categories)
    }

    // MARK: - Sign-in

    /// Finishes sign-in with the backend's `cyruslyrics://...?token=<token>`
    /// redirect.
    func signIn(callbackURL: URL) async {
        let token = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "token" }?
            .value

        guard let token, !token.isEmpty else {
            Logger.auth.error("Sign-in callback didn't include a token")
            return
        }

        oauthToken = token
        tokenStore.save(token)
        await refreshUserFiles()
    }

    func signOut() {
        if isUserFile {
            resetActiveFileToDefault()
        }

        oauthToken = nil
        userFiles = []
        tokenStore.delete()
        store.remove(.userFiles)
    }

    /// Moves the token from UserDefaults, where versions 2.1 and earlier kept
    /// it, to the Keychain. Also clears a token left in the Keychain by a
    /// previous install, since deleting the app doesn't erase the Keychain.
    private func migrateToken() {
        if !store.bool(for: .hasLaunched) {
            tokenStore.delete()
            store.set(true, for: .hasLaunched)
        }

        if let legacyToken = store.string(for: .legacyOAuthToken) {
            if !legacyToken.isEmpty {
                tokenStore.save(legacyToken)
            }

            store.remove(.legacyOAuthToken)
        }
    }

    // MARK: - Connection

    private func startMonitoringConnection() {
        monitor.pathUpdateHandler = { @Sendable [weak self] path in
            let isConnected = path.status == .satisfied

            Task { @MainActor in
                self?.isConnected = isConnected
            }
        }

        monitor.start(queue: DispatchQueue(label: "com.cyruskrauss.cyruslyrics.connection"))
    }
}
