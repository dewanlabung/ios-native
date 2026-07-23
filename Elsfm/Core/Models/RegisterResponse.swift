import Foundation

struct RegisterResponse: Decodable {
    let bootstrapData: BootstrapData

    struct BootstrapData: Decodable {
        let user: User
    }

    enum CodingKeys: String, CodingKey {
        case bootstrapData = "bootstrap_data"
    }
}
