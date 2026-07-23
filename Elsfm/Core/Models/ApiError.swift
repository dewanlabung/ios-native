import Foundation

struct ApiError: Decodable {
    let message: String?
    let errors: [String: [String]]?
}
