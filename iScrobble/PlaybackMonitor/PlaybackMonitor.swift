import Foundation
import AppKit

/// Holds parsed notification data — all properties are Sendable.
private struct TrackNotification: Sendable {
    let playerState: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let elapsed: TimeInterval
}

@Observable
@MainActor
final class PlaybackMonitor {

    private(set) var currentTrack: Track?
    private(set) var isPlaying: Bool = false
    private(set) var playbackElapsed: TimeInterval = 0

    var onTrackStarted: (@MainActor (Track) -> Void)?
    var onTrackStopped: (@MainActor () -> Void)?
    var onPlaybackStateChanged: (@MainActor (Bool) -> Void)?

    private var observer: NSObjectProtocol?
    private var lastTrackID: String?
    private let lastFMClient: LastFMClient

    init(lastFMClient: LastFMClient) {
        self.lastFMClient = lastFMClient
    }

    func start() async {
        print("[PlaybackMonitor] Registering observer for 'com.apple.Music.playerInfo'")
        observer = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Extract only Sendable primitives from the notif before crossing actor boundary
            let info = notification.userInfo
            print("[PlaybackMonitor] Received notification — userInfo: \(info ?? [:])")
            let parsed = TrackNotification(
                playerState: info?["Player State"] as? String ?? "",
                title: info?["Name"] as? String ?? "",
                artist: info?["Artist"] as? String ?? "",
                album: info?["Album"] as? String ?? "",
                duration: (info?["Total Time"] as? Double ?? 0) / 1000.0,
                elapsed: info?["Player Position"] as? Double ?? 0
            )
            Task { @MainActor in
                self?.handleNotification(parsed)
            }
        }
        print("[PlaybackMonitor] Observer registered — waiting for Music.app events")
    }

    func stop() {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
            self.observer = nil
            print("[PlaybackMonitor] Observer removed")
        }
    }

    private func handleNotification(_ parsed: TrackNotification) {
        print("[PlaybackMonitor] Player State: \"\(parsed.playerState)\"")

        if parsed.playerState == "Stopped" {
            if currentTrack != nil {
                currentTrack = nil
                lastTrackID = nil
                print("[PlaybackMonitor] Track stopped")
                onTrackStopped?()
            }
            if isPlaying {
                isPlaying = false
                onPlaybackStateChanged?(false)
            }
            playbackElapsed = 0
            return
        }

        let newIsPlaying = parsed.playerState == "Playing"

        guard !parsed.title.isEmpty else {
            print("[PlaybackMonitor] Empty title — ignoring notification")
            return
        }

        print("[PlaybackMonitor] Parsed — title: \"\(parsed.title)\" | artist: \"\(parsed.artist)\" | album: \"\(parsed.album)\" | duration: \(String(format: "%.1f", parsed.duration))s | elapsed: \(String(format: "%.1f", parsed.elapsed))s | state: \(parsed.playerState)")

        let trackID = "\(parsed.artist)-\(parsed.title)"
        if trackID != lastTrackID {
            lastTrackID = trackID

            let track = Track(
                id: trackID,
                title: parsed.title,
                artist: parsed.artist,
                album: parsed.album,
                duration: parsed.duration,
                albumArt: nil
            )
            currentTrack = track
            print("[PlaybackMonitor] Track changed → \"\(parsed.artist) — \(parsed.title)\"")
            onTrackStarted?(track)

            Task { [weak self] in
                guard let self = self else { return }
                // Try MediaRemote first — in-memory, ~10ms
                if let mrImage = await MediaRemoteArtwork.fetchArtwork() {
                    guard self.lastTrackID == trackID else { return }
                    self.currentTrack = Track(
                        id: trackID, title: parsed.title, artist: parsed.artist,
                        album: parsed.album, duration: parsed.duration, albumArt: mrImage
                    )
                    print("[PlaybackMonitor] Album art from MediaRemote")
                    return
                }
                // Fall back to Last.fm API
                do {
                    print("[PlaybackMonitor] MediaRemote had no art, trying Last.fm...")
                    if let albumArt = try await self.lastFMClient.fetchAlbumArt(artist: parsed.artist, track: parsed.title) {
                        print("[PlaybackMonitor] Album art fetched successfully")
                        let updatedTrack = Track(
                            id: trackID,
                            title: parsed.title,
                            artist: parsed.artist,
                            album: parsed.album,
                            duration: parsed.duration,
                            albumArt: albumArt
                        )
                        currentTrack = updatedTrack
                    } else {
                        print("[PlaybackMonitor] No album art available from Last.fm")
                    }
                } catch {
                    print("[PlaybackMonitor] Failed to fetch album art: \(error.localizedDescription)")
                }
            }
        }

        if newIsPlaying != isPlaying {
            isPlaying = newIsPlaying
            print("[PlaybackMonitor] Playback state → \(newIsPlaying ? "playing" : "paused/stopped")")
            onPlaybackStateChanged?(newIsPlaying)
        }

        playbackElapsed = parsed.elapsed
    }
}
