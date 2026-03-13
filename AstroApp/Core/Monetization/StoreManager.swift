import StoreKit

@Observable
final class StoreManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false

    static let natalChartID = "com.duygubal.AstroApp.natalchart"
    static let aiChatID = "com.duygubal.AstroApp.aichat"
    static let allFeaturesID = "com.duygubal.AstroApp.allfeatures"

    private let productIDs: Set<String> = [
        natalChartID, aiChatID, allFeaturesID
    ]

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await restorePurchases() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Ürünler yüklenemedi: \(error)")
        }
        isLoading = false
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
            return true
        case .pending, .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? Self.checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    func isPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? Self.checkVerified(result) {
                    await MainActor.run {
                        self.purchasedProductIDs.insert(transaction.productID)
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
