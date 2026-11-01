import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var error: String?

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    featuresGrid
                    productsSection
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AstroTheme.textSecondary)
                    .padding(10)
                    .background(AstroTheme.surface, in: .circle)
            }
            .padding()
        }
    }

    // MARK: - Başlık

    private var header: some View {
        VStack(spacing: 10) {
            Text("✦")
                .font(.system(size: 40))
                .foregroundStyle(AstroTheme.accent)

            Text("Doğum Haritanı Aç")
                .font(.title2)
                    .fontDesign(.serif)
                .foregroundStyle(.white)

            Text("Tek seferlik ödeme — abonelik yok")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
        }
        .padding(.top, 40)
    }

    // MARK: - Özellikler

    private var featuresGrid: some View {
        VStack(spacing: 10) {
            featureRow(icon: "star.circle.fill", title: "Tam Doğum Haritası", subtitle: "Tüm gezegen, ev ve açı yorumları")
            featureRow(icon: "clock.arrow.circlepath", title: "Hayat Döngüleri ve Anılar", subtitle: "O kişinin tüm dönem ve anı yorumları")
            featureRow(icon: "infinity", title: "Kalıcı", subtitle: "Bir kez öde, haritan hep açık kalsın")
        }
        .glassCard()
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AstroTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(AstroTheme.harmonik)
        }
    }

    // MARK: - Ürünler

    private var productsSection: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty {
                if store.isLoading {
                    ProgressView()
                        .tint(AstroTheme.accent)
                        .padding()
                } else {
                    Text("Ürünler yüklenemedi")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .padding()
                }
            } else {
                ForEach(store.products, id: \.id) { product in
                    productCard(product)
                }
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AstroTheme.zorlayici)
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        return Button {
            Task { await purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AstroTheme.accentGradient, in: .capsule)
            }
            .padding(14)
            .background(AstroTheme.surfaceElevated, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AstroTheme.accent.opacity(0.3), lineWidth: 1)
            }
        }
        .disabled(isPurchasing)
    }

    // MARK: - Satın Al

    private func purchase(_ product: Product) async {
        isPurchasing = true
        error = nil
        do {
            // Bekleyen ödeme (ebeveyn/banka onayı) sonradan onaylanınca kredi kendiliğinden eklenir
            let success = try await store.purchase(product)
            if success { dismiss() }
        } catch {
            self.error = "Satın alma başarısız oldu."
        }
        isPurchasing = false
    }
}
