import XCTest
@testable import Elsfm

// MARK: - Mocks

/// In-memory token store. Replaces KeychainTokenStore so tests never touch Keychain.
final class MockTokenStore: TokenStore {
    private(set) var savedToken: String?
    private(set) var clearCallCount = 0

    func save(_ token: String) async throws {
        savedToken = token
    }

    func read() async -> String? {
        savedToken
    }

    func clear() async {
        savedToken = nil
        clearCallCount += 1
    }
}

/// Fake AuthApi controlled by tests.
/// Set `loginResult` before calling `viewModel.login()`.
final class MockAuthApi: AuthApiProtocol {
    var loginResult: ApiResult<LoginResponse> = .networkError(
        URLError(.notConnectedToInternet)
    )
    var loginWithGoogleResult: ApiResult<LoginResponse> = .networkError(
        URLError(.notConnectedToInternet)
    )
    var logoutResult: ApiResult<Void> = .success(())

    private(set) var loginCallCount = 0
    private(set) var lastLoginEmail: String?
    private(set) var lastLoginPassword: String?

    func login(email: String, password: String, tokenName: String) async -> ApiResult<LoginResponse> {
        loginCallCount += 1
        lastLoginEmail = email
        lastLoginPassword = password
        return loginResult
    }

    func loginWithGoogle(googleAccessToken: String, tokenName: String) async -> ApiResult<LoginResponse> {
        loginWithGoogleResult
    }

    func register(email: String, password: String, tokenName: String) async -> ApiResult<LoginResponse> {
        .networkError(URLError(.notConnectedToInternet))
    }

    func requestPasswordReset(email: String) async -> ApiResult<Void> {
        .networkError(URLError(.notConnectedToInternet))
    }

    func logout() async -> ApiResult<Void> {
        logoutResult
    }
}

// MARK: - Tests

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var mockApi: MockAuthApi!
    private var mockTokenStore: MockTokenStore!
    private var sessionManager: SessionManager!
    private var viewModel: LoginViewModel!

    override func setUp() async throws {
        try await super.setUp()
        mockApi = MockAuthApi()
        mockTokenStore = MockTokenStore()
        sessionManager = SessionManager(tokenStore: mockTokenStore)
        viewModel = LoginViewModel(authApi: mockApi, sessionManager: sessionManager)
    }

    override func tearDown() async throws {
        viewModel = nil
        sessionManager = nil
        mockTokenStore = nil
        mockApi = nil
        try await super.tearDown()
    }

    // MARK: - Initial state

    func testInitialEmailIsEmpty() {
        XCTAssertTrue(viewModel.email.isEmpty)
    }

    func testInitialPasswordIsEmpty() {
        XCTAssertTrue(viewModel.password.isEmpty)
    }

    func testInitialIsLoadingIsFalse() {
        XCTAssertFalse(viewModel.isLoading)
    }

    func testInitialErrorsIsEmpty() {
        XCTAssertTrue(viewModel.errors.isEmpty)
    }

    // MARK: - Validation errors for empty credentials
    //
    // LoginViewModel delegates validation to the server. These tests verify
    // that server-side validation errors for empty fields are correctly stored
    // in viewModel.errors so the UI can display them.

    func testEmptyEmailAndPasswordShowValidationErrors() async throws {
        // Server responds with validation errors for blank fields
        mockApi.loginResult = .validationError([
            "email":    ["The email field is required."],
            "password": ["The password field is required."]
        ])

        viewModel.email = ""
        viewModel.password = ""
        viewModel.login()

        // Drain the unstructured Task spawned by login()
        await drainSpawnedTask()

        XCTAssertFalse(viewModel.errors.isEmpty, "errors should be populated after validation failure")
        XCTAssertNotNil(viewModel.errors["email"], "email error should be present")
        XCTAssertNotNil(viewModel.errors["password"], "password error should be present")
        XCTAssertEqual(viewModel.errors["email"]?.first, "The email field is required.")
        XCTAssertEqual(viewModel.errors["password"]?.first, "The password field is required.")
    }

    func testEmptyEmailAloneShowsEmailValidationError() async throws {
        mockApi.loginResult = .validationError([
            "email": ["The email field is required."]
        ])

        viewModel.email = ""
        viewModel.password = "somepassword"
        viewModel.login()

        await drainSpawnedTask()

        XCTAssertNotNil(viewModel.errors["email"])
        XCTAssertNil(viewModel.errors["password"])
    }

    // MARK: - Successful login stores token

    func testSuccessfulLoginStoresToken() async throws {
        let expectedToken = "test-bearer-token-abc123"
        mockApi.loginResult = .success(
            LoginResponse(
                token: expectedToken,
                user: User(
                    id: 1,
                    email: "user@example.com",
                    name: "Test User",
                    image: nil,
                    followersCount: 0,
                    followingCount: 0
                )
            )
        )

        viewModel.email = "user@example.com"
        viewModel.password = "correct-password"
        viewModel.login()

        await drainSpawnedTask()

        XCTAssertEqual(
            mockTokenStore.savedToken,
            expectedToken,
            "Token returned by the API should be persisted in the token store"
        )
        XCTAssertEqual(
            sessionManager.currentToken,
            expectedToken,
            "SessionManager.currentToken should reflect the saved token"
        )
        XCTAssertTrue(viewModel.errors.isEmpty, "No errors should be set after a successful login")
    }

    func testSuccessfulLoginClearsPreexistingErrors() async throws {
        // Seed a pre-existing error state (e.g. from a previous failed attempt)
        mockApi.loginResult = .validationError(["email": ["Bad email."]])
        viewModel.login()
        await drainSpawnedTask()
        XCTAssertFalse(viewModel.errors.isEmpty)

        // Now succeed
        mockApi.loginResult = .success(
            LoginResponse(
                token: "new-token",
                user: User(id: 2, email: "a@b.com", name: nil, image: nil,
                           followersCount: nil, followingCount: nil)
            )
        )
        viewModel.login()
        await drainSpawnedTask()

        XCTAssertTrue(viewModel.errors.isEmpty)
    }

    // MARK: - Unauthorized populates general error

    func testUnauthorizedSetsEmailError() async throws {
        mockApi.loginResult = .unauthorized

        viewModel.email = "user@example.com"
        viewModel.password = "wrong"
        viewModel.login()

        await drainSpawnedTask()

        XCTAssertNotNil(viewModel.errors["email"])
        XCTAssertEqual(viewModel.errors["email"]?.first, "Invalid email or password.")
    }

    // MARK: - Network error populates general error

    func testNetworkErrorSetsGeneralError() async throws {
        mockApi.loginResult = .networkError(URLError(.notConnectedToInternet))

        viewModel.login()
        await drainSpawnedTask()

        XCTAssertNotNil(viewModel.errors["general"])
    }

    // MARK: - isLoading lifecycle

    func testIsLoadingIsFalseAfterLoginCompletes() async throws {
        mockApi.loginResult = .success(
            LoginResponse(
                token: "tok",
                user: User(id: 1, email: "a@a.com", name: nil, image: nil,
                           followersCount: nil, followingCount: nil)
            )
        )

        viewModel.login()
        await drainSpawnedTask()

        XCTAssertFalse(viewModel.isLoading, "isLoading should be false once the task completes")
    }

    // MARK: - Mock receives correct credentials

    func testLoginPassesEmailAndPasswordToApi() async throws {
        mockApi.loginResult = .networkError(URLError(.timedOut))

        viewModel.email = "test@elsfm.com"
        viewModel.password = "s3cr3t"
        viewModel.login()

        await drainSpawnedTask()

        XCTAssertEqual(mockApi.lastLoginEmail, "test@elsfm.com")
        XCTAssertEqual(mockApi.lastLoginPassword, "s3cr3t")
        XCTAssertEqual(mockApi.loginCallCount, 1)
    }

    // MARK: - Helpers

    /// Suspends the current task enough times to let the unstructured Task
    /// spawned inside LoginViewModel.login() run to completion.
    /// The mock API returns synchronously (no real async work), so a few
    /// cooperative yields are sufficient.
    private func drainSpawnedTask() async {
        // Each yield hands control back to the executor so pending tasks run.
        for _ in 0..<5 {
            await Task.yield()
        }
    }
}
