# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Cursor, Copilot, etc.) working in this repository. `CLAUDE.md` imports this file, so keep shared instructions here.

## Project at a glance

CyrusLyrics is a small **SwiftUI iOS app** (iPhone + iPad) for quickly finding song lyrics while singing. Songs are organized as **Category → Sub-category → Song** (in practice, Genre → Artist → Song). The data lives in **Google Sheets**, and a few preloaded lists ship by default. Signed-in users can create and manage their own lists.

- Language: Swift 6 language mode (strict concurrency checking), SwiftUI. No UIKit app delegate. The entry point is `CyrusLyrics/CyrusLyricsApp.swift`.
- Deployment target: iOS 17.0.
- Bundle ID: `com.cyruskrauss.cyruslyrics`. URL scheme: `cyruslyrics://`.
- **No third-party dependencies**: no SPM, CocoaPods, or Carthage. Keeping it that way is a product goal, because the in-app FAQ promises "no external plugins". Don't add a package without asking.
- Unit tests use **Swift Testing** in the `CyrusLyricsTests` target.
- The backend API (`https://api.cyruskrauss.com`) is a **separate project that isn't in this repo**. It handles Google OAuth and the Google Sheets/Drive calls for user-owned lists.

## Repository layout

```
CyrusLyrics/
  CyrusLyricsApp.swift      App entry; creates StateManager and puts it in the environment
  Pages/                    Screen-level SwiftUI views (HomeView is the home screen)
  Components/               Reusable views (LyricsView, WebView, ShuffleToolbarItem, PillButtonStyle)
  Services/
    StateManager.swift      App state: lists, active list's songs, sign-in (@Observable, @MainActor)
    APIClient.swift         Backend and Google requests (async/await, typed throws)
    SheetParser.swift       Turns sheet rows into [AppCategory]; default lyrics URL
    ShuffleBag.swift        Random order without repeats
    LocalStore.swift        UserDefaults cache
    TokenStore.swift        OAuth token in the Keychain
  Models/                   Codable models: songs/categories, API responses, gviz format, FAQ content
  Preview Content/          Preview assets and sample data (StateManager.preview())
  PrivacyInfo.xcprivacy     Privacy manifest (required-reason APIs)
  Assets.xcassets           App icon, Primary/Accent colors, google-logo
CyrusLyricsTests/           Swift Testing unit tests
CyrusLyrics.xcodeproj/      Xcode project (folder-synced groups) and the shared CyrusLyrics scheme
```

## Architecture notes

- **State**: `StateManager` is `@Observable` and `@MainActor`. `CyrusLyricsApp` owns one instance and injects it with `.environment(stateManager)`. Views read it with `@Environment(StateManager.self)`. There's no singleton. Its dependencies (`APIClient`, `LocalStore`, `TokenStore`) are passed to `init`, which is how tests and previews isolate it.
- **Networking**: `APIClient` uses `URLSession` async/await and throws `RequestError`. Only its private `send` method talks to the backend, and that's the only place the `Authorization: Bearer` header is added, so the token never goes to Google. `RequestError.invalidatesSession` decides sign-out: a 4xx, or a 2xx whose body can't be decoded, signs the user out when listing sheets or loading a user list. Create and delete sign out only on 401/403. Network errors and 5xx responses keep the user signed in and keep cached data.
- **Loading the active list**: `open(_:)` switches lists, clears the previous list's songs, and starts a load. Each new load cancels the previous one, and results are ignored if the active list changed meanwhile. Lists load on launch, on switch, and on pull to refresh (`refreshActiveFile()`), not every time the list screen appears.
- **Two data paths**, both parsed by `SheetParser`:
  - *Default (preloaded) lists*: fetched directly from Google's public `gviz` endpoint (`APIFile.publicDataURL`). The JSON is extracted from between the first `{` and the last `}` of the JSONP response. If the response can't be parsed, the cached songs are kept.
  - *User lists*: fetched from the backend (`/sheets/:id`). An empty sheet has no `values` key.
- **Sheet format**: row 1 is headers. Columns are `Category | Sub-category | Song name | URL (optional) | Lyrics (optional) | Spotify URL (optional)`. Cells are trimmed. Rows missing any of the first 3 columns are skipped. Without a URL, the app falls back to a Google search, built in `SheetParser.defaultLyricsURL`. Categories, sub-categories, and songs are sorted with `localizedStandardCompare`.
- **Persistence**: `LocalStore` wraps `UserDefaults` with these keys: `defaultFiles`, `userFiles`, `categories`, `activeFile`, `hasLaunched`, and the legacy `oauthQuery`. Values are encoded with `PropertyListEncoder`, so the stored property names in `Models/Library.swift` and `APIFile` are part of the on-disk format. Cached data is what makes offline mode work, so don't rename keys or properties without a migration.
- **Token**: kept in the Keychain by `TokenStore`. On launch, `StateManager` moves a token found under the legacy `oauthQuery` key into the Keychain. On the first launch of a new install (no `hasLaunched`), it clears any Keychain token left by a previous install.
- **Auth flow**: `HomeView` opens `APIClient.signInURL` (`/oauth/google`) in an `ASWebAuthenticationSession`. The backend redirects to `cyruslyrics://login?token=<token>&...`, which the session returns to `StateManager.signIn(callbackURL:)`. `onOpenURL` handles the same callback as a fallback.
- **Backend endpoints used**: `GET /sheets`, `GET /sheets/default`, `GET /sheets/:id`, `POST /sheets?title=`, `DELETE /sheets/:id`, `GET /oauth/google`.
- **Local backend**: while developing, create the state manager in `CyrusLyricsApp` as `StateManager(api: APIClient(baseURL: <tunnel URL>))`, for example with an ngrok URL. Never commit a non-production URL.

## Building, running, and testing

The usual workflow is to open `CyrusLyrics.xcodeproj` in Xcode and run on a simulator or device.

From the command line (requires a full Xcode install selected with `xcode-select`, not just the Command Line Tools):

```sh
# Build
xcodebuild -project CyrusLyrics.xcodeproj -target CyrusLyrics \
  -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build

# Test (pick any available simulator from `xcrun simctl list devices available`)
xcodebuild test -project CyrusLyrics.xcodeproj -scheme CyrusLyrics \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

The build should have no warnings. There is no linter or formatter config. Match the surrounding style.

## Conventions

- 4-space indentation. Each new Swift file starts with the standard Xcode header comment (`//  FileName.swift`, `//  CyrusLyrics`, `//  Created by ...`).
- Each SwiftUI view file ends with a `#Preview`. Use `StateManager.preview()` and the sample data in `Preview Content/PreviewData.swift` for views that need app state.
- Prefer async/await over completion handlers and `@MainActor` over `DispatchQueue.main`. Keep the code free of strict concurrency warnings.
- Avoid force unwraps, except for URL string literals that are known to be valid.
- Model types live in `Models/` and are `Codable` and `Sendable` when they are persisted.
- Add tests in `CyrusLyricsTests/` for logic changes. Network tests use `TestEnvironment` from `TestSupport.swift`, which stubs requests and isolates UserDefaults and the Keychain per test.
- Keep changes small and focused. This is a personal app with a released App Store version. `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj` are bumped only for releases.

## Gotchas for agents

- **Adding files**: the project uses folder-synced groups (`objectVersion = 77`). Any file created under `CyrusLyrics/` or `CyrusLyricsTests/` is automatically part of that target, so adding, renaming, or deleting files doesn't require editing `project.pbxproj`. `CyrusLyrics/Info.plist` is excluded from the app target's membership because it's referenced by `INFOPLIST_FILE`. Keep any other non-bundled files out of those folders.
- Don't hand-edit `project.pbxproj` beyond what the task needs, and never reformat it.
- `DEVELOPMENT_TEAM` and signing settings belong to the maintainer's Apple account. Don't change them.
- `Info.plist` declares `LSApplicationQueriesSchemes: googlesheets`, which is required for `canOpenURL` checks on the Google Sheets app, and the `cyruslyrics` URL scheme. Both are load-bearing.
- If you start using another required-reason API (file timestamps, disk space, system boot time, and so on), declare it in `PrivacyInfo.xcprivacy`.
- The FAQ text in `Models/FAQItem.swift` is user-facing copy. Update it when user-visible behavior changes.
