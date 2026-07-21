import Foundation
import AppKit

/// Private MediaRemote.framework wrapper — reads Now Playing artwork
/// directly via MRMediaRemoteGetNowPlayingInfo, no subprocess.
/// Based on the approach from TheBoredTeam/boring.notch (BSD-3).
enum MediaRemoteArtwork {

    // MARK: - Private framework types

    private typealias MRMediaRemoteGetNowPlayingInfoFunction =
        @convention(c) (DispatchQueue, @escaping (CFDictionary?) -> Void) -> Void

    // MARK: - State

    private static let queue = DispatchQueue(label: "com.hexif.iScrobble.mediaRemote", qos: .userInitiated)
    private static var _getNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction?
    private static var _artworkDataKey: NSString?

    // MARK: - Public

    /// Fetch album art for the current Now Playing track (async, non-blocking).
    /// Returns nil on any failure (framework missing, no track, no artwork data).
    static func fetchArtwork() async -> NSImage? {
        guard loadFramework() else { return nil }

        return await withCheckedContinuation { continuation in
            guard let fn = _getNowPlayingInfo else {
                continuation.resume(returning: nil)
                return
            }
            fn(queue) { info in
                guard let info = info as? [NSString: Any],
                      let key = _artworkDataKey,
                      let artData = info[key] as? Data,
                      let image = NSImage(data: artData) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Framework loading

    private static func loadFramework() -> Bool {
        if _getNowPlayingInfo != nil { return true }

        let frameworkPath = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"

        guard FileManager.default.fileExists(atPath: frameworkPath) else {
            print("[MediaRemote] Framework not found at \(frameworkPath)")
            return false
        }

        guard let handle = dlopen(frameworkPath, RTLD_NOW) else {
            let err = dlerror().map { String(cString: $0) } ?? "unknown error"
            print("[MediaRemote] dlopen failed: \(err)")
            return false
        }

        guard let symbol = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else {
            print("[MediaRemote] MRMediaRemoteGetNowPlayingInfo symbol not found")
            return false
        }
        _getNowPlayingInfo = unsafeBitCast(symbol, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

        // kMRMediaRemoteNowPlayingInfoArtworkData is NSString *const — dlsym returns
        // pointer to the constant's storage, not the string itself.
        if let artKey = dlsym(handle, "kMRMediaRemoteNowPlayingInfoArtworkData") {
            _artworkDataKey = artKey.assumingMemoryBound(to: NSString.self).pointee
            print("[MediaRemote] Loaded artwork key, value: \"\(_artworkDataKey!)\"")
        } else {
            print("[MediaRemote] kMRMediaRemoteNowPlayingInfoArtworkData not found, falling back to string literal")
        }

        print("[MediaRemote] Loaded successfully")
        return true
    }
}
