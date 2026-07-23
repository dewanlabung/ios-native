import Foundation
import StoreKit

@Observable
@MainActor
final class SubscriptionsViewModel {

    private static let productIDs = [
        "com.elsfm.mobile.premium.monthly",
        "com.elsfm.mobile.premium.annual"
    ]

    var products: [Product] = []
    var isLoading = false
    var error: String?
    var purchaseInProgress = false

    func loadProducts() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            products = fetched.sorted { a, b in
                let order = Self.productIDs
                let ai = order.firstIndex(of: a.id) ?? Int.max
                let bi = order.firstIndex(of: b.id) ?? Int.max
                return ai < bi
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        error = nil
        defer { purchaseInProgress = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                case .unverified:
                    error = "Purchase could not be verified."
                }
            case .pending:
                break
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            try await AppStore.sync()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
