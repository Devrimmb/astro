import StoreKit

@Observable
final class StoreManager {
    var products: [Product] = []
    var isLoading = false

    static let natalChartID = "com.duygubal.AstroApp.natalchart"

    /// Tek ürün: doğum haritası (tek seferlik). PRO / abonelik / "tüm özellikler" paketi yok.
    private let productIDs: Set<String> = [natalChartID]

    // MARK: - Consumable Kredi Sistemi

    private static let chartCreditsKey = "natal_chart_credits"

    /// Mevcut harita hesaplama kredisi. Saklı özellik: sonradan onaylanan bir ödeme kredi eklediğinde ekranlar güncellenir.
    var chartCredits: Int = UserDefaults.standard.integer(forKey: chartCreditsKey) {
        didSet { UserDefaults.standard.set(chartCredits, forKey: Self.chartCreditsKey) }
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

    // MARK: - İşlem teslimi
    //
    // Doğum haritası tüketilebilir (Consumable) bir ürün: Apple bunu yeniden açılışta ya da "geri yükle" ile
    // geri vermez, kalıcı karşılığı cihazdaki kredi ve kişi başına kaydedilen okumadır (`ChartReadingStore`).
    // Bir işlem üç yoldan gelebilir: anlık satın alma, sonradan onaylanan ödeme (ebeveyn onayı, banka onayı)
    // ya da önceki açılışta bitirilmemiş işlem. Hepsi `deliver` üzerinden geçer; her işlem en fazla bir kez kredi ekler.

    private static let deliveredTransactionsKey = "delivered_transaction_ids"

    private var deliveredTransactionIDs: Set<UInt64> {
        get { Set((UserDefaults.standard.array(forKey: Self.deliveredTransactionsKey) as? [UInt64]) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: Self.deliveredTransactionsKey) }
    }

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await deliverUnfinishedTransactions() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            let loaded = try await Product.products(for: productIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            print("❌ StoreKit ürün yükleme hatası: \(error)")
        }
        isLoading = false
    }

    /// - Returns: true ise ödeme tamamlandı ve kredi eklendi; bekleyen/iptal edilen ödemede false
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            await deliver(transaction)
            return true
        case .pending, .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    private func deliver(_ transaction: Transaction) async {
        if transaction.productID == Self.natalChartID,
           transaction.revocationDate == nil,
           !deliveredTransactionIDs.contains(transaction.id) {
            deliveredTransactionIDs.insert(transaction.id)
            addChartCredit()
        }
        await transaction.finish()
    }

    private func deliverUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            if let transaction = try? Self.checkVerified(result) {
                await deliver(transaction)
            }
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? Self.checkVerified(result) {
                    await self.deliver(transaction)
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
