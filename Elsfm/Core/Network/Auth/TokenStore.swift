import Foundation
import Security

// MARK: - Protocol

protocol TokenStore {
    func save(_ token: String) async throws
    func read() async -> String?
    func clear() async
}

// MARK: - Keychain Implementation

final class KeychainTokenStore: TokenStore {

    private let service = "com.elsfm.mobile"
    private let tokenKey = "auth_token"

    func save(_ token: String) async throws {
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
        let attrs: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: tokenKey,
            kSecValueData: data
        ]
        let status = SecItemAdd(attrs as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
    }

    func read() async -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: tokenKey,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func clear() async {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Error

private enum KeychainError: Error {
    case saveFailed(OSStatus)
}
