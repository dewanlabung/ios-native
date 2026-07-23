import Foundation
import KeychainAccess

// MARK: - Protocol

protocol TokenStore {
    func save(_ token: String) async throws
    func read() async -> String?
    func clear() async
}

// MARK: - Keychain Implementation

final class KeychainTokenStore: TokenStore {

    private let keychain = Keychain(service: "com.elsfm.mobile")
    private let tokenKey = "auth_token"

    func save(_ token: String) async throws {
        try keychain.set(token, key: tokenKey)
    }

    func read() async -> String? {
        try? keychain.get(tokenKey)
    }

    func clear() async {
        try? keychain.remove(tokenKey)
    }
}
