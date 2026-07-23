import XCTest
@testable import Elsfm

final class ApiResultTests: XCTestCase {

    // MARK: - success

    func testSuccessCarriesValue() {
        let result: ApiResult<Int> = .success(42)

        guard case .success(let value) = result else {
            XCTFail("Expected .success but got a different case")
            return
        }
        XCTAssertEqual(value, 42)
    }

    func testSuccessCarriesStringValue() {
        let result: ApiResult<String> = .success("hello")

        guard case .success(let value) = result else {
            XCTFail("Expected .success")
            return
        }
        XCTAssertEqual(value, "hello")
    }

    func testSuccessIsDistinctFromOtherCases() {
        let result: ApiResult<Int> = .success(1)
        if case .validationError = result { XCTFail("Should not be validationError") }
        if case .unauthorized = result    { XCTFail("Should not be unauthorized") }
        if case .networkError = result    { XCTFail("Should not be networkError") }
    }

    // MARK: - validationError

    func testValidationErrorCarriesFields() {
        let fields: [String: [String]] = [
            "email":    ["The email is required.", "Must be a valid email address."],
            "password": ["The password is required."]
        ]
        let result: ApiResult<String> = .validationError(fields)

        guard case .validationError(let returned) = result else {
            XCTFail("Expected .validationError")
            return
        }
        XCTAssertEqual(returned["email"]?.count, 2)
        XCTAssertEqual(returned["email"]?.first, "The email is required.")
        XCTAssertEqual(returned["password"]?.first, "The password is required.")
    }

    func testValidationErrorCanCarryEmptyDictionary() {
        let result: ApiResult<Int> = .validationError([:])

        guard case .validationError(let fields) = result else {
            XCTFail("Expected .validationError")
            return
        }
        XCTAssertTrue(fields.isEmpty)
    }

    func testValidationErrorPreservesMultipleFieldKeys() {
        let fields: [String: [String]] = [
            "name":  ["Name is required."],
            "email": ["Email is required."],
            "age":   ["Age must be a number."]
        ]
        let result: ApiResult<Void> = .validationError(fields)

        guard case .validationError(let returned) = result else {
            XCTFail("Expected .validationError")
            return
        }
        XCTAssertEqual(returned.keys.sorted(), ["age", "email", "name"])
    }

    // MARK: - unauthorized

    func testUnauthorizedMatchesCorrectly() {
        let result: ApiResult<Int> = .unauthorized

        var matched = false
        if case .unauthorized = result { matched = true }
        XCTAssertTrue(matched, "Expected .unauthorized to match")
    }

    func testUnauthorizedIsDistinctFromOtherCases() {
        let result: ApiResult<String> = .unauthorized
        if case .success      = result { XCTFail("Should not be success") }
        if case .validationError = result { XCTFail("Should not be validationError") }
        if case .networkError = result { XCTFail("Should not be networkError") }
    }

    // MARK: - networkError

    func testNetworkErrorCarriesUnderlyingError() {
        let underlying = URLError(.notConnectedToInternet)
        let result: ApiResult<Int> = .networkError(underlying)

        guard case .networkError(let error) = result else {
            XCTFail("Expected .networkError")
            return
        }
        let urlError = try? XCTUnwrap(error as? URLError)
        XCTAssertEqual(urlError?.code, .notConnectedToInternet)
    }

    func testNetworkErrorPreservesErrorMessage() {
        struct DummyError: Error, LocalizedError {
            var errorDescription: String? { "Connection refused" }
        }
        let result: ApiResult<String> = .networkError(DummyError())

        guard case .networkError(let error) = result else {
            XCTFail("Expected .networkError")
            return
        }
        XCTAssertEqual(error.localizedDescription, "Connection refused")
    }

    // MARK: - Switch exhaustiveness

    /// Verifies that a switch statement covering all four cases compiles and
    /// routes each variant to exactly the right branch at runtime.
    func testSwitchCoversAllFourCases() {
        let cases: [ApiResult<Int>] = [
            .success(99),
            .validationError(["x": ["y"]]),
            .unauthorized,
            .networkError(URLError(.timedOut))
        ]

        var seen: Set<String> = []

        for result in cases {
            switch result {
            case .success:          seen.insert("success")
            case .validationError:  seen.insert("validationError")
            case .unauthorized:     seen.insert("unauthorized")
            case .networkError:     seen.insert("networkError")
            }
        }

        XCTAssertEqual(seen, ["success", "validationError", "unauthorized", "networkError"])
    }
}
