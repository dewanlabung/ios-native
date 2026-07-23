import XCTest
@testable import Elsfm

/// Tests for PlayerState initial values and repeatMode cycle.
/// PlayerState is @Observable and mutated exclusively from PlaybackService
/// (which is @MainActor), so we run tests on the main actor to match production access.
@MainActor
final class PlayerStateTests: XCTestCase {

    private var state: PlayerState!

    override func setUp() async throws {
        try await super.setUp()
        state = PlayerState()
    }

    override func tearDown() async throws {
        state = nil
        try await super.tearDown()
    }

    // MARK: - Initial state (mirrors Android PlayerState defaults)

    func testInitialCurrentTrackIsNil() {
        XCTAssertNil(state.currentTrack)
    }

    func testInitialIsPlayingIsFalse() {
        XCTAssertFalse(state.isPlaying)
    }

    func testInitialPositionMsIsZero() {
        XCTAssertEqual(state.positionMs, 0.0, accuracy: 0.001)
    }

    func testInitialDurationMsIsZero() {
        XCTAssertEqual(state.durationMs, 0.0, accuracy: 0.001)
    }

    func testInitialQueueIsEmpty() {
        XCTAssertTrue(state.queue.isEmpty)
    }

    func testInitialShuffleIsDisabled() {
        XCTAssertFalse(state.shuffleEnabled)
    }

    func testInitialRepeatModeIsOff() {
        XCTAssertEqual(state.repeatMode, .off)
    }

    func testInitialErrorIsNil() {
        XCTAssertNil(state.error)
    }

    func testInitialSleepTimerIsNil() {
        XCTAssertNil(state.sleepTimerMillisLeft)
    }

    func testInitialPlaybackSpeedIsOne() {
        XCTAssertEqual(state.playbackSpeed, 1.0, accuracy: 0.001)
    }

    func testInitialVolumeIsOne() {
        XCTAssertEqual(state.volume, 1.0, accuracy: 0.001)
    }

    // MARK: - repeatMode cycle: off → all → one → off
    //
    // PlaybackService.cycleRepeatMode() implements:
    //   .off  → .all
    //   .all  → .one
    //   .one  → .off
    // These tests verify that each transition produces the expected value
    // when we apply the same mapping to PlayerState.repeatMode.

    func testRepeatModeCycleOffToAll() {
        XCTAssertEqual(state.repeatMode, .off)
        state.repeatMode = cycled(state.repeatMode)
        XCTAssertEqual(state.repeatMode, .all)
    }

    func testRepeatModeCycleAllToOne() {
        state.repeatMode = .all
        state.repeatMode = cycled(state.repeatMode)
        XCTAssertEqual(state.repeatMode, .one)
    }

    func testRepeatModeCycleOneBackToOff() {
        state.repeatMode = .one
        state.repeatMode = cycled(state.repeatMode)
        XCTAssertEqual(state.repeatMode, .off)
    }

    func testRepeatModeCycleFullRound() {
        // Start: off
        XCTAssertEqual(state.repeatMode, .off)

        state.repeatMode = cycled(state.repeatMode)   // off  → all
        XCTAssertEqual(state.repeatMode, .all)

        state.repeatMode = cycled(state.repeatMode)   // all  → one
        XCTAssertEqual(state.repeatMode, .one)

        state.repeatMode = cycled(state.repeatMode)   // one  → off
        XCTAssertEqual(state.repeatMode, .off)
    }

    func testRepeatModeCycleTwoFullRounds() {
        for _ in 0..<2 {
            state.repeatMode = cycled(state.repeatMode)
            XCTAssertEqual(state.repeatMode, .all)
            state.repeatMode = cycled(state.repeatMode)
            XCTAssertEqual(state.repeatMode, .one)
            state.repeatMode = cycled(state.repeatMode)
            XCTAssertEqual(state.repeatMode, .off)
        }
    }

    // MARK: - Helpers

    /// Applies the same transition logic as PlaybackService.cycleRepeatMode().
    private func cycled(_ mode: PlayerRepeatMode) -> PlayerRepeatMode {
        switch mode {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }
}
