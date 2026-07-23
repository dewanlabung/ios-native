import Foundation

/// Countdown timer that drives `PlayerState.sleepTimerMillisLeft` and fires a
/// callback when the deadline is reached.  Mirrors Android `SleepTimer.kt`.
@Observable
final class SleepTimer {

    // MARK: - Private state

    private let playerState: PlayerState
    private var countdownTask: Task<Void, Never>?

    // MARK: - Init

    init(playerState: PlayerState) {
        self.playerState = playerState
    }

    // MARK: - Public API

    /// Start (or restart) the timer.
    ///
    /// - Parameters:
    ///   - durationMs: Total countdown in milliseconds.
    ///   - onExpired: Called on the main actor when the countdown reaches zero.
    func start(durationMs: Double, onExpired: @escaping @Sendable () -> Void) {
        cancel()

        playerState.sleepTimerMillisLeft = durationMs

        countdownTask = Task { [weak self] in
            var remainingMs = durationMs

            while remainingMs > 0 {
                // Sleep one second (1 000 000 000 ns).
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    // Task was cancelled mid-sleep — exit cleanly.
                    return
                }

                remainingMs -= 1_000
                let snapshot = max(0, remainingMs)

                await MainActor.run { [weak self] in
                    self?.playerState.sleepTimerMillisLeft = snapshot
                }
            }

            // Countdown finished normally — fire callback and clear state.
            await MainActor.run { [weak self] in
                self?.playerState.sleepTimerMillisLeft = nil
                onExpired()
            }
        }
    }

    /// Cancel an in-progress countdown.  No-op when no timer is active.
    func cancel() {
        countdownTask?.cancel()
        countdownTask = nil
        playerState.sleepTimerMillisLeft = nil
    }
}
