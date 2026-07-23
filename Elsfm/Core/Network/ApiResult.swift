import Foundation

enum ApiResult<T> {
    case success(T)
    case validationError([String: [String]])
    case unauthorized
    case networkError(Error)
}
