import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
    let tokenName: String

    enum CodingKeys: String, CodingKey {
        case email, password
        case tokenName = "token_name"
    }
}
