import Foundation

struct CompletePasswordResetRequest: Encodable {
    let email: String
    let token: String
    let password: String
    let passwordConfirmation: String

    enum CodingKeys: String, CodingKey {
        case email, token, password
        case passwordConfirmation = "password_confirmation"
    }
}
