<p align="center">
  <img src="https://thecodeboss.dev/wp-content/uploads/2021/08/cl-1.jpeg" alt="CyrusLyrics logo" width="80" height="80">
</p>

<h3 align="center">CyrusLyrics</h3>

<p align="center">
  A simple iOS app that I built to help me quickly find the lyrics to songs as
  I sang to my son. And it just got bigger from there.
  <br />
  <br />
  <a href="https://github.com/alkrauss48/cyrus-lyrics/issues">Report Bug</a>
  ·
  <a href="https://github.com/alkrauss48/cyrus-lyrics/issues">Request Feature</a>
</p>

## Contents

- [About](#about)
- [Built With](#built-with)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [How the Data Works](#how-the-data-works)
- [AI-Assisted Development](#ai-assisted-development)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## About

CyrusLyrics organizes songs as **Genre → Artist → Song** and shows each song's lyrics in-app. It also links out to Spotify and can shuffle a random song at any level. The app ships with a few preloaded lists. Signed-in users can create their own lists, and those lists are stored as Google Sheets in their own Google account.

Features:

- Browse songs by category and sub-category, and pull to refresh
- Lyrics from a Google search, a custom URL, or lyrics you paste in yourself
- Shuffle across all songs, one genre, or one artist
- Open songs in Spotify
- Sign in with Google to create, edit, and delete your own lists
- Offline support for the last selected list (cached on the device)

## Built With

- Swift 6 / SwiftUI, with Observation and async/await
- iOS 17.0+ (iPhone and iPad)
- Swift Testing for unit tests
- No third-party dependencies
- [Google Sheets](https://www.google.com/sheets/about/) as the data store
- A companion backend API (`api.cyruskrauss.com`, not in this repo) that handles Google OAuth and access to user-owned sheets

## Getting Started

### Prerequisites

- macOS with [Xcode](https://developer.apple.com/xcode/) 16 or newer installed

### Installation

1. Clone the repo:
   ```sh
   git clone https://github.com/alkrauss48/cyrus-lyrics.git
   ```
2. Open `CyrusLyrics.xcodeproj` in Xcode.
3. Select an iOS simulator or device and run.

There are no packages to install.

### Command-line build and tests

```sh
xcodebuild -project CyrusLyrics.xcodeproj -target CyrusLyrics \
  -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build

xcodebuild test -project CyrusLyrics.xcodeproj -scheme CyrusLyrics \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Replace `iPhone 17` with any simulator from `xcrun simctl list devices available`.

You need a full Xcode install selected with `sudo xcode-select -s /Applications/Xcode.app`. The Command Line Tools alone aren't enough.

### Running on a device

The project's signing team is the maintainer's. To run it on your own device, change the **Team** (and the bundle identifier if needed) under *Signing & Capabilities* in Xcode. Don't commit that change.

## Project Structure

```
CyrusLyrics/
  CyrusLyricsApp.swift   App entry point
  Pages/                 Screen-level views (HomeView is the home screen)
  Components/            Reusable views (lyrics, web view, shuffle button, button style)
  Services/              StateManager (app state), APIClient (networking),
                         SheetParser, ShuffleBag, and local/Keychain storage
  Models/                Data models, API/Sheet response models, FAQ content
CyrusLyricsTests/        Unit tests (Swift Testing)
```

## How the Data Works

Each list is a Google Sheet with a header row and these six columns:

| Column | Name        | Required | Purpose                                               |
| ------ | ----------- | -------- | ----------------------------------------------------- |
| A      | Category    | Yes      | Top-level grouping (e.g. genre)                       |
| B      | Sub-category| Yes      | Second-level grouping (e.g. artist)                   |
| C      | Song        | Yes      | Song name                                             |
| D      | URL         | No       | Overrides the default Google lyrics search            |
| E      | Lyrics      | No       | Custom lyrics, shown directly and available offline   |
| F      | Spotify URL | No       | Enables the "open in Spotify" button                  |

Preloaded lists are read from Google's public sheet endpoint. User lists are read and managed through the backend API using the user's Google OAuth token, which the app keeps in the Keychain.

## AI-Assisted Development

This repo is set up for AI coding agents:

- [`AGENTS.md`](AGENTS.md): the main guide for agents. It covers architecture, conventions, build and test commands, and gotchas.
- [`CLAUDE.md`](CLAUDE.md): Claude Code entry point. It imports `AGENTS.md`.
- `.editorconfig`: shared formatting basics for editors and agents.

Put personal agent settings in `.claude/settings.local.json` and personal notes in `CLAUDE.local.md`. Git ignores both.

## Contributing

Contributions are welcome!

1. Fork the project.
2. Create a feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push the branch (`git push origin feature/AmazingFeature`).
5. Open a pull request.

Please keep the app free of third-party dependencies, and read [`AGENTS.md`](AGENTS.md) for project conventions.

## License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for more information.

## Contact

[Aaron Krauss - Personal Site](https://thecodeboss.dev)

Project link: [https://github.com/alkrauss48/cyrus-lyrics](https://github.com/alkrauss48/cyrus-lyrics)
