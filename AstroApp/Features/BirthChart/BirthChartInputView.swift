import SwiftUI
import StoreKit

struct BirthChartInputView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var calculatedChart: BirthChart?
    @State private var isCalculating = false
    @State private var isPurchasing = false
    @State private var showResult = false
    @State private var showPaymentRequired = false

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 6) {
                            Text("Doğum Haritası")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Yıldızların sana ne söylüyor?")
                                .font(.subheadline)
                                .foregroundStyle(AstroTheme.textSecondary)
                        }
                        .padding(.top, 20)

                        PersonSelectionCard(
                            title: "Kişi Seçin",
                            buttonTitle: isCalculating ? "Hesaplanıyor..." : "Haritayı Hesapla",
                            buttonIcon: "star.circle.fill"
                        ) { birthData in
                            handleCalculateRequest(birthData)
                        }
                        .disabled(isCalculating || isPurchasing)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showResult) {
                if let chart = calculatedChart {
                    BirthChartResultView(chart: chart)
                }
            }
            .sheet(isPresented: $showPaymentRequired) {
                ChartPaymentSheet(
                    onPurchased: {
                        showPaymentRequired = false
                        // Kredi eklendi, tekrar hesapla
                        if let data = pendingBirthData {
                            Task { await calculateChart(for: data) }
                        }
                    }
                )
            }
        }
    }

    @State private var pendingBirthData: BirthData?

    private func handleCalculateRequest(_ data: BirthData) {
        if entitlements.canCalculateChart {
            // Hak var, direkt hesapla
            Task { await calculateChart(for: data) }
        } else {
            // Hak yok, ödeme iste
            pendingBirthData = data
            showPaymentRequired = true
        }
    }

    private func calculateChart(for data: BirthData) async {
        isCalculating = true

        // Admin değilse kredi harca
        if !EntitlementManager.isAdmin {
            appState.store.consumeChartCredit()
        }

        let coords = WorldCityStore.coordinates(for: data.cityName, countryCode: "TR")
        let tz = TimeZone(identifier: coords.tz) ?? TimeZone(identifier: "Europe/Istanbul")!

        let chart = await appState.ephemeris.calculateBirthChart(
            date: data.birthDate,
            latitude: data.latitude,
            longitude: data.longitude,
            timeZone: tz
        )
        calculatedChart = chart
        isCalculating = false
        showResult = true
    }
}

// MARK: - Ödeme Sheet

struct ChartPaymentSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    var onPurchased: () -> Void

    private var product: Product? {
        appState.store.products.first { $0.id == StoreManager.natalChartID }
    }

    var body: some View {
        ZStack {
            // Gradient arka plan
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.04, blue: 0.15),
                    Color(red: 0.1, green: 0.06, blue: 0.25),
                    Color(red: 0.06, green: 0.04, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Kapat butonu
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(.white.opacity(0.1), in: .circle)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Hero bölümü
                    VStack(spacing: 16) {
                        // Yıldız animasyonu
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [AstroTheme.accent.opacity(0.3), .clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 70
                                    )
                                )
                                .frame(width: 140, height: 140)

                            Image(systemName: "sparkles")
                                .font(.system(size: 52))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AstroTheme.accent, .white],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text("Yıldız Haritanı Keşfet")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)

                        Text("Doğum anındaki gökyüzünün sırlarını\ndetaylı bir harita ile keşfet")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                    // Özellikler
                    VStack(spacing: 0) {
                        featureRow(icon: "circle.hexagongrid.fill", title: "Yıldız Haritası Çarkı", subtitle: "12 ev ve gezegen pozisyonları")
                        dividerLine
                        featureRow(icon: "moon.stars.fill", title: "Gezegen Analizleri", subtitle: "Tüm gezegenler, burçlar ve evlerde yorumlar")
                        dividerLine
                        featureRow(icon: "arrow.triangle.branch", title: "Açı Analizleri", subtitle: "Gezegen açıları ve ilişki dinamikleri")
                        dividerLine
                        featureRow(icon: "text.book.closed.fill", title: "Detaylı Yorumlar", subtitle: "Kişiselleştirilmiş astrolojik okuma")
                        dividerLine
                        featureRow(icon: "square.and.arrow.up.fill", title: "Paylaşım", subtitle: "Haritanı görsel olarak paylaş")
                    }
                    .padding(.vertical, 16)
                    .background(.white.opacity(0.04), in: .rect(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 28)

                    // Fiyat ve satın al
                    if let product {
                        VStack(spacing: 12) {
                            // Fiyat
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(product.displayPrice)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("/ hesaplama")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }

                            // Satın al butonu
                            Button {
                                Task { await purchaseChart(product) }
                            } label: {
                                HStack(spacing: 8) {
                                    if isPurchasing {
                                        ProgressView().tint(.white)
                                    }
                                    Text(isPurchasing ? "İşleniyor..." : "Haritamı Hesaplat")
                                        .font(.headline)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [AstroTheme.accent, AstroTheme.accent.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: .rect(cornerRadius: 16)
                                )
                                .shadow(color: AstroTheme.accent.opacity(0.3), radius: 12, y: 4)
                            }
                            .disabled(isPurchasing)
                            .padding(.horizontal, 20)

                            // Kredi bilgisi
                            if appState.store.chartCredits > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                    Text("\(appState.store.chartCredits) hesaplama hakkınız mevcut")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(AstroTheme.accent)
                            Text("Fiyat bilgisi yükleniyor...")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.top, 8)
                    }

                    // Alt bilgi
                    Text("Tek seferlik ödeme. Abonelik değildir.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .task {
            if appState.store.products.isEmpty {
                await appState.store.loadProducts()
            }
        }
    }

    private func purchaseChart(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        do {
            let success = try await appState.store.purchase(product)
            if success {
                onPurchased()
            }
        } catch {
            errorMessage = "Satın alma başarısız: \(error.localizedDescription)"
        }
        isPurchasing = false
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
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
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(.white.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
}
