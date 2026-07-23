import SwiftUI
import StoreKit

struct SubscriptionsView: View {

    @State private var viewModel = SubscriptionsViewModel()

    var body: some View {
        ZStack {
            paywallBackground
            content
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadProducts() }
    }

    private var paywallBackground: some View {
        LinearGradient(
            colors: [
                Color.elsfmPrimary.opacity(0.22),
                Color.elsfmBackground.opacity(0.95),
                Color.elsfmBackground
            ],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.55)
        )
        .ignoresSafeArea()
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 32)

                if viewModel.isLoading {
                    loadingSection
                } else if let error = viewModel.error, viewModel.products.isEmpty {
                    errorSection(error)
                } else {
                    productCardsSection
                }

                footerSection
                    .padding(.top, 32)
            }
            .padding(.bottom, 40)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.elsfmPrimary.opacity(0.15))
                    .frame(width: 76, height: 76)
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.elsfmPrimary)
            }

            VStack(spacing: 8) {
                Text("Go Premium")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.elsfmText)

                Text("Unlimited music, completely ad-free.")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 36)
    }

    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.elsfmPrimary)
            Text("Loading plans…")
                .font(.system(size: 14))
                .foregroundStyle(Color.elsfmTextSecondary)
        }
        .padding(.vertical, 60)
    }

    private func errorSection(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.elsfmPrimary.opacity(0.7))

            Text("Could not load plans")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.elsfmText)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.elsfmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                Task { await viewModel.loadProducts() }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.elsfmOnPrimary)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.elsfmPrimary)
            .clipShape(Capsule())
        }
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
    }

    private var productCardsSection: some View {
        VStack(spacing: 14) {
            if let error = viewModel.error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)
            }

            ForEach(viewModel.products, id: \.id) { product in
                ProductCard(
                    product: product,
                    isPurchasing: viewModel.purchaseInProgress
                ) {
                    Task { await viewModel.purchase(product) }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var footerSection: some View {
        VStack(spacing: 18) {
            Divider()
                .background(Color.elsfmDivider)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.restorePurchases() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.75)
                            Text("Restoring…")
                        }
                    } else {
                        Text("Restore Purchases")
                    }
                }
                .font(.system(size: 15))
                .foregroundStyle(Color.elsfmTextSecondary)
            }
            .disabled(viewModel.isLoading || viewModel.purchaseInProgress)

            Text("Subscription renews automatically unless cancelled at least 24 hours before the end of the current period.")
                .font(.system(size: 11))
                .foregroundStyle(Color.elsfmTextSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

private struct ProductCard: View {

    let product: Product
    let isPurchasing: Bool
    let onSubscribe: () -> Void

    private var isAnnual: Bool {
        product.id.contains("annual")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.elsfmText)

                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.elsfmTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 12)

                if isAnnual {
                    Text("Best Value")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.elsfmOnPrimary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.elsfmPrimary)
                        .clipShape(Capsule())
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(product.displayPrice)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.elsfmText)

                Text(billingLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.elsfmTextSecondary)
            }

            subscribeButton
        }
        .padding(20)
        .background(Color.elsfmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isAnnual ? Color.elsfmPrimary.opacity(0.5) : Color.elsfmDivider,
                    lineWidth: isAnnual ? 1.5 : 1
                )
        )
    }

    private var subscribeButton: some View {
        Button {
            onSubscribe()
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(Color.elsfmOnPrimary)
                } else {
                    Text("Subscribe")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.elsfmOnPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.elsfmPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isPurchasing)
    }

    private var billingLabel: String {
        if product.id.contains("monthly") { return "/ month" }
        if product.id.contains("annual") { return "/ year" }
        return ""
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SubscriptionsView()
    }
    .preferredColorScheme(.dark)
}
#endif
