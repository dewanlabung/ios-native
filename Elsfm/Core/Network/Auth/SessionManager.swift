import Foundation
import Observation

@Observable
final class SessionManager {

    // MARK: - Singleton

    static let shared = SessionManager()

    // MARK: - Observable State

    private(set) var currentToken: String?

    // MARK: - Event Stream

    private var continuation: AsyncStream<SessionEvent>.Continuation?

    let events: AsyncStream<SessionEvent>

    // MARK: - Dependencies

    private let tokenStore: TokenStore

    // MARK: - Init

    init(tokenStore: TokenStore = KeychainTokenStore()) {
        self.tokenStore = tokenStore

        var capturedContinuation: AsyncStream<SessionEvent>.Continuation?
        events = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        self.continuation = capturedContinuation

        Task { [weak self] in
            self?.currentToken = await tokenStore.read()
        }
    }

    // MARK: - Methods

    func saveToken(_ token: String) async {
        try? await tokenStore.save(token)
        currentToken = token
    }

    func readToken() async -> String? {
        await tokenStore.read()
    }

    func clear() async {
        await tokenStore.clear()
        currentToken = nil
    }

    func notifyExpired() async {
        await clear()
        continuation?.yield(.expired)
    }
}
