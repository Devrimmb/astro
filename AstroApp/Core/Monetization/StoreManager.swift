import StoreKit

@Observable
final class StoreManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false

    static let natalChartID = "com.duygubal.AstroApp.natalchart"
    static let allFeaturesID = "com.duygubal.AstroApp.allfeatures"

    private let productIDs: Set<String> = [
        natalChartID, allFeaturesID
    ]

    // MARK: - Consumable Kredi Sistemi

    private static let chartCreditsKey = "natal_chart_credits"

    /// Mevcut harita hesaplama kredisi
    var chartCredits: Int {
        get { UserDefaults.standard.integer(forKey: Self.chartCreditsKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.chartCreditsKey) }
    }

    /// Kredi ekle (satın alma sonrası)
    func addChartCredit() {
        chartCredits += 1
    }

    /// Kredi harca (hesaplama öncesi)
    /// - Returns: true ise kredi vardı ve harcandı
    @discardableResult
    func consumeChartCredit() -> Bool {
        guard chartCredits > 0 else { return false }
        chartCredits -= 1
        return true
    }

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

            // Consumable ürünlerde kredi ekle
            if transaction.productID == Self.natalChartID {
                addChartCredit()
            }

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
