import Foundation

struct BillingApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getPlans() async -> ApiResult<[SubscriptionPlan]> {
        await client.get("api/v1/billing/plans")
    }

    func getActiveSubscription() async -> ApiResult<ActiveSubscription?> {
        await client.get("api/v1/user/subscription")
    }
}

// MARK: - Models

struct SubscriptionPlan: Codable, Identifiable {
    let id: Int
    let name: String
    let price: String
    let interval: String
    let features: [String]?
}

struct ActiveSubscription: Codable, Identifiable {
    let id: Int
    let planId: Int
    let status: String
    let expiresAt: String?
}
