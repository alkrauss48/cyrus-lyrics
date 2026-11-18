# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Cursor, Copilot, etc.) working in this repository. `CLAUDE.md` imports this file, so keep shared instructions here.

## Project at a glance

CyrusLyrics is a small **SwiftUI iOS app** (iPhone + iPad) for quickly finding song lyrics while singing. Songs are organized as **Category → Sub-category → Song** (in practice, Genre → Artist → Song). The data lives in **Google Sheets**, and a few preloaded lists ship by default. Signed-in users can create and manage their own lists.

- Language: Swift 5, SwiftUI. No UIKit app delegate. The entry point is `CyrusLyrics/CyrusLyricsApp.swift`.
- Deployment target: iOS 15.0 (the app target's setting; the project-level setting of 14.4 is overridden).
- Bundle ID: `com.cyruskrauss.cyruslyrics`. URL scheme: `cyruslyrics://`.
- **No third-party dependencies**: no SPM, CocoaPods, or Carthage. Keeping it that way is a product goal, because the in-app FAQ promises "no external plugins". Don't add a package without asking.
- **No tests or test target** exist yet.
- The backend API (`https://api.cyruskrauss.com`) is a **separate project that isn't in this repo**. It handles Google OAuth and the Google Sheets/Drive calls for user-owned lists.

## Repository layout

```
CyrusLyrics/
  CyrusLyricsApp.swift      App entry; handles the cyruslyrics:// OAuth callback (?token=...)
  Pages/                    Screen-level SwiftUI views (SetDataView is the home screen)
  Components/               Reusable views (LyricsView, SpotifyButton, WebView/SafariView, toolbar items)
  Services/
    StateManager.swift      Global app state, networking, and persistence (singleton ObservableObject)
    ShuffleManager.swift    Random song selection at the all/category/sub-category level
    DataAdapters/           Turn Google Sheet data into [AppCategory]
  Protocols/SheetsAdapter.swift
  Structs/                  Codable models: app data, API responses, GSheet formats, FAQ content
  Utilities/                Small helpers (default Google-search lyrics URL)
  Assets.xcassets           App icon, Primary/Accent colors, google-logo
CyrusLyrics.xcodeproj/      Xcode project (legacy format, see "Adding files" below)
```

## Architecture notes

- **State**: `StateManager` is a process-wide singleton (`StateManager.Get()`). Views bind to it with `@StateObject var stateManager = StateManager.Get()`. All `@Published` mutations must happen on the main thread; the existing code wraps them in `DispatchQueue.main.async`.
- **Networking**: `StateManager.makeRequest` uses `URLSession` with completion handlers (not async/await) and sends `Authorization: Bearer <oauthToken>`. Failed decodes of authenticated responses call `logOut()` on purpose.
- **Two data paths**:
  - *Default (preloaded) lists*: fetched directly from Google's public `gviz` endpoint through `SheetsV2Adapter`. It strips a fixed 47-character JSONP prefix and a 2-character suffix from the response before decoding.
  - *User lists*: fetched from the backend (`/sheets/:id`) and parsed by `OAuthSheetAdapter`.
  - `SheetsV1Adapter` is **deprecated**: Google's old feed API stopped working in August 2021. It's kept only for reference.
- **Sheet format** (all adapters): row 1 is headers. Columns are `Category | Sub-category | Song name | URL (optional) | Lyrics (optional) | Spotify URL (optional)`. Rows missing any of the first 3 columns are skipped. Without a URL, the app falls back to a Google search, built in `Utilities.getDefaultGoogleUrl`.
- **Persistence**: `UserDefaults` only, using these keys: `oauthQuery`, `defaultFiles`, `userFiles`, `categories`, `activeFile`. Values are encoded with `PropertyListEncoder`. Cached data is what makes offline mode work, so don't rename these keys without a migration.
- **Auth flow**: the app opens `BASE_API_URL/oauth/google`, and the backend redirects to `cyruslyrics://...?token=<token>`. `CyrusLyricsApp.onOpenURL` stores the token and reloads the user's sheets.
- **Backend endpoints used**: `GET /sheets`, `GET /sheets/default`, `GET /sheets/:id`, `POST /sheets?title=`, `DELETE /sheets/:id`, `GET /oauth/google`.
- **Local backend**: swap `StateManager.BASE_API_URL` for the commented-out ngrok line. Never commit a non-production URL.

## Building and running

The usual workflow is to open `CyrusLyrics.xcodeproj` in Xcode and run on a simulator or device.

To build from the command line (requires a full Xcode install selected with `xcode-select`, not just the Command Line Tools):

```sh
xcodebuild -project CyrusLyrics.xcodeproj -target CyrusLyrics \
  -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

The project has no shared scheme checked in, so use `-target` rather than `-scheme`. There is no linter or formatter config. Match the surrounding style.

## Conventions

- 4-space indentation. Each new Swift file starts with the standard Xcode header comment (`//  FileName.swift`, `//  CyrusLyrics`, `//  Created by ...`).
- Each SwiftUI view file ends with a `*_Previews: PreviewProvider` struct. Keep it working when you edit a view.
- Model types live in `Structs/` and are `Codable` when they are persisted.
- Keep changes small and focused. This is a personal app with a released App Store version. `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj` are bumped only for releases.

## Gotchas for agents

- **Adding files**: this is an older Xcode project format (`objectVersion = 50`), not folder-synced groups. **Creating a `.swift` file on disk doesn't add it to the build.** It needs `PBXFileReference`, `PBXGroup`, `PBXBuildFile`, and `PBXSourcesBuildPhase` entries in `project.pbxproj`. Either edit the pbxproj carefully, with unique 24-hex-character IDs that follow the existing entries, or ask the human to add the file in Xcode. Renames and deletes need the same care.
- Don't hand-edit `project.pbxproj` beyond what the task needs, and never reformat it.
- `DEVELOPMENT_TEAM` and signing settings belong to the maintainer's Apple account. Don't change them.
- `Info.plist` declares `LSApplicationQueriesSchemes: googlesheets`, which is required for `canOpenURL` checks on the Google Sheets app, and the `cyruslyrics` URL scheme. Both are load-bearing.
- The FAQ text in `Structs/FAQStructs.swift` is user-facing copy. Update it when user-visible behavior changes.
- The code uses force unwraps and `try!` in several places, for example in `SheetsV2Adapter` and `ShuffleManager`. Be careful when touching those paths, but don't refactor them unless the task asks for it.
