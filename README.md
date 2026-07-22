<div align="center">
  <img src="READMEAssets/icon.png" alt="iScrobble Logo" width="125">
  <h1>iScrobble</h1>
  <p>Last.fm scrobbler for Apple Music on MacOS</p>
</div>

## About this project
I built this as the native last.fm scrobbler for macos is stopping support for silicon macs (i think) and the annoying "Support ending for Intel-based Apps" notification. iScrobble is built entirely on swift and uses the free last.fm API for scrobbling tracks and logging in. 

**Built on MacOS Version 26.4 Beta (25E5223i), unsure if it works on other versions.**

## Interface

### Main interface

<img src="READMEAssets/mainview-preview.png" width="300">

### Widget Support
iScrobble supports lovely widgets showing scrobble stats for the day and the currently playing song

<img src="READMEAssets/widget-preview.png" width="300">

### Settings
Super simple settings screen, lastfm api configuration is below this.

<img src="READMEAssets/settings-preview.png" width="300">

## How to install

Currently, iScrobble must be built from source.

Pre-built releases are unavailable until a Developer ID signing and notarisation workflow is configured.

See the "How to build from source" section below.

## How to build from source

### Prerequisites
- Xcode and Git installed
- An active Apple Developer account (for signing)

### Build Instructions

1. Clone the repository:

```bash
git clone https://github.com/xHeXifx/iScrobble
cd iScrobble
```

2. Build the application:

```bash
xcodebuild \
  -scheme iScrobble \
  -destination 'generic/platform=macOS' \
  clean build \
  CODE_SIGN_IDENTITY="Apple Development" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates
```

Xcode may prompt you to sign in with your Apple ID.

3. Locate the built application:

The generated app will be located in the Xcode build output directory.

Alternatively, open:

```text
iScrobble.xcodeproj
```

in Xcode and use:

```text
Product → Archive
```

Then:

```text
Distribute App
→ Custom
→ Copy App
```

Choose an output location.

4. Move the generated:

```text
iScrobble.app
```

to:

```text
/Applications
```

for full macOS functionality.

### Troubleshooting
- If you encounter signing errors, ensure your Apple ID is added in Xcode Preferences → Accounts

## Known Issues
  - Clicking items on sub-views (e.g. settings view/api cred view) closes the menu. To click some stuff you'll have to go back and click the item AGAIN for it to trigger

## [LICENSE](/LICENSE)