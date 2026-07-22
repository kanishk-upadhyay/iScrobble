import Foundation

// Shared constants for App Group communication between main app and widget extension.
// Must be a member of both the iScrobble and iScrobbleWidgetExtension targets.

enum SharedDefaults {
    static let appGroupID = "group.com.hexif.iScrobble"
    static let scrobblingEnabled = "scrobblingEnabled"
    static let launchAtLogin = "launchAtLogin"
}
