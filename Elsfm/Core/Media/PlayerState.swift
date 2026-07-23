import Foundation

enum PlayerRepeatMode: String, CaseIterable {
    case off, all, one
}

@Observable
final class PlayerState {
    var currentTrack: Track? = nil
    var isPlaying: Bool = false
    var positionMs: Double = 0
    var durationMs: Double = 0
    var queue: [Track] = []
    var shuffleEnabled: Bool = false
    var repeatMode: PlayerRepeatMode = .off
    var error: String? = nil
    var sleepTimerMillisLeft: Double? = nil
    var playbackSpeed: Float = 1.0
    var volume: Float = 1.0
}
