import AVFoundation
import MediaPlayer
import Foundation

// MARK: - PlaybackService

/// AVFoundation-backed singleton that drives all audio playback.
/// `state` is the single source of truth consumed by the UI layer.
@Observable
@MainActor
final class PlaybackService {

    // MARK: - Singleton

    static let shared = PlaybackService()

    // MARK: - Public state

    let state = PlayerState()

    // MARK: - Private: player infrastructure

    private var player = AVQueuePlayer()
    private var timeObserverToken: Any?
    private var playerStatusObservation: NSKeyValueObservation?
    private var currentItemObservation: NSKeyValueObservation?
    private var endOfQueueObservationTask: Task<Void, Never>?

    // MARK: - Private: queue management

    /// Original (unshuffled) track list. Preserved so we can de-shuffle.
    private var originalQueue: [Track] = []
    /// Active playback order (may be shuffled).
    private var activeQueue: [Track] = []
    private var currentQueueIndex: Int = 0

    // MARK: - Sub-services

    private(set) lazy var sleepTimer = SleepTimer(playerState: state)

    // MARK: - Init

    private init() {
        configureAudioSession()
        attachPeriodicTimeObserver()
        attachPlayerObservations()
        subscribeToItemEndNotifications()
        registerRemoteCommands()
    }

    // MARK: - Public playback API

    /// Replace the queue with a single track and start playing immediately.
    func play(track: Track) {
        loadQueue(tracks: [track], startIndex: 0)
    }

    /// Load `tracks` as the new playback queue and start at `startIndex`.
    func playQueue(tracks: [Track], startIndex: Int) {
        loadQueue(tracks: tracks, startIndex: startIndex)
    }

    func pause() {
        player.pause()
    }

    func resume() {
        player.play()
    }

    func skipNext() {
        let nextIndex: Int

        if state.shuffleEnabled {
            // Pick a random track that isn't the current one (if the queue has > 1 item).
            if activeQueue.count > 1 {
                var candidate: Int
                repeat { candidate = Int.random(in: 0 ..< activeQueue.count) } while candidate == currentQueueIndex
                nextIndex = candidate
            } else {
                nextIndex = 0
            }
        } else {
            let proposed = currentQueueIndex + 1
            if proposed < activeQueue.count {
                nextIndex = proposed
            } else if state.repeatMode == .all {
                nextIndex = 0
            } else {
                // End of queue, no repeat — stop.
                player.pause()
                return
            }
        }

        jumpToIndex(nextIndex)
    }

    func skipPrevious() {
        // Rewind if we're more than 3 s into the track; otherwise go back one.
        if state.positionMs > 3_000 {
            seek(to: 0)
            return
        }

        let prevIndex: Int
        if currentQueueIndex > 0 {
            prevIndex = currentQueueIndex - 1
        } else if state.repeatMode == .all {
            prevIndex = activeQueue.count - 1
        } else {
            seek(to: 0)
            return
        }

        jumpToIndex(prevIndex)
    }

    func seek(to positionMs: Double) {
        let target = CMTime(seconds: positionMs / 1_000, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setSpeed(_ speed: Float) {
        state.playbackSpeed = speed
        if state.isPlaying {
            player.rate = speed
        }
    }

    func setVolume(_ volume: Float) {
        state.volume = volume
        player.volume = volume
    }

    func toggleShuffle() {
        state.shuffleEnabled.toggle()

        guard !activeQueue.isEmpty else { return }
        let currentTrack = activeQueue[currentQueueIndex]

        if state.shuffleEnabled {
            // Shuffle, but keep current track at position 0 so play continues.
            var shuffled = originalQueue.filter { $0.id != currentTrack.id }.shuffled()
            shuffled.insert(currentTrack, at: 0)
            activeQueue = shuffled
            currentQueueIndex = 0
        } else {
            // Restore original order, anchoring to the current track.
            activeQueue = originalQueue
            currentQueueIndex = originalQueue.firstIndex(where: { $0.id == currentTrack.id }) ?? 0
        }

        state.queue = activeQueue
        rebuildAVQueueFromCurrentIndex(autoPlay: state.isPlaying)
    }

    func cycleRepeatMode() {
        switch state.repeatMode {
        case .off: state.repeatMode = .all
        case .all: state.repeatMode = .one
        case .one: state.repeatMode = .off
        }
    }

    // MARK: - Private: queue loading

    private func loadQueue(tracks: [Track], startIndex: Int) {
        guard !tracks.isEmpty, tracks.indices.contains(startIndex) else { return }

        originalQueue = tracks
        activeQueue = tracks
        currentQueueIndex = startIndex
        state.queue = tracks

        rebuildAVQueueFromCurrentIndex(autoPlay: true)
    }

    /// Rebuild `AVQueuePlayer` so it starts from `currentQueueIndex`.
    /// Items after the current index are pre-loaded for gapless playback.
    private func rebuildAVQueueFromCurrentIndex(autoPlay: Bool) {
        removeTimeObserver()
        player.pause()
        player.removeAllItems()

        let tracksToLoad = activeQueue[currentQueueIndex...]
        let items: [AVPlayerItem] = tracksToLoad.compactMap { track in
            guard let srcString = track.src,
                  let url = resolvedURL(for: srcString) else { return nil }
            return AVPlayerItem(url: url)
        }

        guard !items.isEmpty else {
            state.error = "No playable tracks in queue."
            return
        }

        for item in items {
            if player.canInsert(item, after: nil) {
                player.insert(item, after: nil)
            }
        }

        updateStateForCurrentTrack()
        attachPeriodicTimeObserver()

        if autoPlay {
            player.rate = state.playbackSpeed
            player.play()
        }
    }

    /// Jump to an arbitrary index in `activeQueue`, rebuilding the player.
    private func jumpToIndex(_ index: Int) {
        guard activeQueue.indices.contains(index) else { return }
        currentQueueIndex = index
        rebuildAVQueueFromCurrentIndex(autoPlay: true)
    }

    // MARK: - Private: state sync

    private func updateStateForCurrentTrack() {
        guard activeQueue.indices.contains(currentQueueIndex) else { return }
        let track = activeQueue[currentQueueIndex]
        state.currentTrack = track
        state.positionMs = 0
        state.durationMs = Double(track.durationMs)
        updateNowPlaying(track: track)
    }

    // MARK: - Private: AVPlayer observations

    private func attachPlayerObservations() {
        playerStatusObservation = player.observe(
            \.timeControlStatus,
            options: [.new, .initial]
        ) { [weak self] player, _ in
            let playing = player.timeControlStatus == .playing
            DispatchQueue.main.async {
                self?.state.isPlaying = playing
                self?.updateNowPlayingPlaybackState(isPlaying: playing)
            }
        }

        currentItemObservation = player.observe(
            \.currentItem,
            options: [.new, .initial]
        ) { [weak self] player, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                // When AVQueuePlayer advances to the next item automatically,
                // update our index so state stays in sync.
                if let item = player.currentItem,
                   let itemURL = (item.asset as? AVURLAsset)?.url {
                    self.syncCurrentIndexForURL(itemURL)
                }
            }
        }
    }

    private func attachPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.state.positionMs = time.seconds * 1_000

            // Keep durationMs accurate once the item reports a finite duration.
            if let currentItem = self.player.currentItem {
                let itemDuration = currentItem.duration
                if itemDuration.isNumeric && !itemDuration.isIndefinite {
                    let durationMs = itemDuration.seconds * 1_000
                    if abs(durationMs - self.state.durationMs) > 1 {
                        self.state.durationMs = durationMs
                    }
                }
            }

            self.updateNowPlayingElapsedTime()
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    // MARK: - Private: end-of-item notification

    private func subscribeToItemEndNotifications() {
        endOfQueueObservationTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: AVPlayerItem.didPlayToEndTimeNotification
            )
            for await _ in notifications {
                await MainActor.run {
                    self?.handleItemPlayedToEnd()
                }
            }
        }
    }

    private func handleItemPlayedToEnd() {
        switch state.repeatMode {
        case .one:
            // Loop current item.
            seek(to: 0)
            player.play()

        case .all:
            // AVQueuePlayer already advanced; sync index then check for wrap-around.
            let nextIndex = currentQueueIndex + 1
            if nextIndex < activeQueue.count {
                // Player has already moved to next item; just update state.
                currentQueueIndex = nextIndex
                updateStateForCurrentTrack()
            } else {
                // Wrap back to beginning.
                jumpToIndex(0)
            }

        case .off:
            let nextIndex = currentQueueIndex + 1
            if nextIndex < activeQueue.count {
                currentQueueIndex = nextIndex
                updateStateForCurrentTrack()
            } else {
                // End of queue — stop.
                state.isPlaying = false
            }
        }
    }

    // MARK: - Private: URL helpers

    private func resolvedURL(for src: String) -> URL? {
        if let url = URL(string: src), url.scheme != nil {
            return url
        }
        // Treat as a path relative to the API base URL.
        return URL(string: src, relativeTo: ElsfmApiConfig.baseURL)
    }

    /// Keep `currentQueueIndex` in sync when `AVQueuePlayer` auto-advances.
    private func syncCurrentIndexForURL(_ url: URL) {
        for (index, track) in activeQueue.enumerated() {
            guard let srcString = track.src,
                  let trackURL = resolvedURL(for: srcString) else { continue }
            if trackURL.absoluteString == url.absoluteString {
                currentQueueIndex = index
                updateStateForCurrentTrack()
                return
            }
        }
    }

    // MARK: - Private: Audio session

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            state.error = "Audio session error: \(error.localizedDescription)"
        }
    }

    // MARK: - Private: Now Playing info

    private func updateNowPlaying(track: Track) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.name,
            MPMediaItemPropertyArtist: track.artists.map(\.name).joined(separator: ", "),
            MPMediaItemPropertyPlaybackDuration: Double(track.durationMs) / 1_000,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: state.positionMs / 1_000,
            MPNowPlayingInfoPropertyPlaybackRate: Double(state.playbackSpeed)
        ]

        if let albumName = track.album?.name {
            info[MPMediaItemPropertyAlbumTitle] = albumName
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        // Artwork: download asynchronously and update when ready.
        if let imageString = track.image ?? track.album?.image,
           let artworkURL = resolvedURL(for: imageString) {
            Task {
                await fetchAndSetArtwork(from: artworkURL, for: track.id)
            }
        }
    }

    private func updateNowPlayingElapsedTime() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = state.positionMs / 1_000
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackState(isPlaying: Bool) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(state.playbackSpeed) : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func fetchAndSetArtwork(from url: URL, for trackID: Int) async {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return }

        // Only apply if we're still on the same track.
        guard state.currentTrack?.id == trackID else { return }

        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }

        await MainActor.run {
            guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
            info[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    // MARK: - Private: Remote command center

    private func registerRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.state.isPlaying ? self.pause() : self.resume()
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipNext()
            return .success
        }

        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipPrevious()
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: positionEvent.positionTime * 1_000)
            return .success
        }
    }
}
