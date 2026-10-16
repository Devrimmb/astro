import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var showPaywall = false
    @State private var showAbout = false
    @State private var showDeviceID = false
    @State private var adminTestMode = EntitlementManager.adminTestMode

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        profileCard
                        proStatusCard
                        languageCard
                        settingsCard
                        if EntitlementManager.isAdminDevice {
                            adminCard
                        }
                        disclaimerCard
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Hakkında", isPresented: $showAbout) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("AstroApp v1.0\nKozmik rehberiniz.\n\nBu uygulama eğlence amaçlıdır, profesyonel danışmanlık yerine geçmez.")
            }
        }
    }

    // MARK: - Profil

    /// Eski ProfileView'ın özeti: doğum bilgisi + Büyük Üçlü, tek kartta.
    private var profileCard: some View {
        Group {
            if let data = appState.birthDataStore.savedData {
                HStack(spacing: 14) {
                    let sunSign = appState.currentChart?.sunSign
                    Text(sunSign?.glyph ?? "✦")
                        .font(.system(size: 24, design: .serif))
                        .foregroundStyle(sunSign.map { AstroTheme.element($0.element) } ?? AstroTheme.accent)
                        .frame(width: 52, height: 52)
                        .background(.white.opacity(0.08), in: .circle)
                        .overlay { Circle().stroke(.white.opacity(0.18), lineWidth: 1) }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.name.isEmpty ? "Profilim" : data.name)
                            .font(.title3)
                            .fontDesign(.serif)
                            .foregroundStyle(.white)
                        if let chart = appState.currentChart {
                            bigThreeLine(chart)
                        }
                        Text("\(formattedDate(data.birthDate)) · \(formattedTime(data.birthDate)) · \(data.cityName)")
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    if entitlements.hasFullAccess {
                        Pill.pro
                    }
                }
                .accessibilityElement(children: .combine)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                        .foregroundStyle(AstroTheme.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Henüz profil oluşturulmadı")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Astroloji sekmesinden doğum bilgilerini girerek haritanı oluştur.")
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .glassCard(tint: AstroTheme.accent)
    }

    private func bigThreeLine(_ chart: BirthChart) -> some View {
        HStack(spacing: 6) {
            if let sun = chart.sunSign {
                Text("☉ \(sun.name)").foregroundStyle(AstroTheme.planet(.sun))
            }
            if let moon = chart.moonSign {
                Text("·").foregroundStyle(AstroTheme.textTertiary)
                Text("☽ \(moon.name)").foregroundStyle(AstroTheme.planet(.moon))
            }
            if let asc = chart.ascendant {
                Text("·").foregroundStyle(AstroTheme.textTertiary)
                Text("AC \(asc.name)").foregroundStyle(AstroTheme.harmonik)
            }
        }
        .font(.caption)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMM yyyy"
        return f.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.timeStyle = .short
        return f.string(from: date)
    }

    // MARK: - Pro Status

    private var proStatusCard: some View {
        VStack(spacing: 12) {
            if entitlements.hasFullAccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AstroTheme.harmonik)
                    Text("Pro Aktif")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Pro abonelik aktif")
                Text("Tüm özelliklere erişiminiz var.")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            } else {
                VStack(spacing: 8) {
                    Text("Tüm Özellikleri Aç")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Detaylı harita, uyumluluk analizi ve daha fazlası")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)

                    Button {
                        showPaywall = true
                    } label: {
                        Text("Pro'ya Geç")
                            .glassButton()
                    }
                    .accessibilityLabel("Pro sürüme geç")
                    .padding(.top, 4)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Language

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .foregroundStyle(AstroTheme.accent)
                Text("Dil")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            LanguageManager.shared.selected = lang
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: lang.icon)
                                .font(.subheadline)
                                .foregroundStyle(isSelected(lang) ? AstroTheme.accent : AstroTheme.textSecondary)
                                .frame(width: 24)

                            Text(lang.displayName)
                                .font(.subheadline)
                                .foregroundStyle(isSelected(lang) ? .white : AstroTheme.textSecondary)

                            Spacer()

                            if isSelected(lang) {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AstroTheme.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            isSelected(lang) ? AstroTheme.accent.opacity(0.1) : .clear,
                            in: .rect(cornerRadius: 10)
                        )
                    }
                }
            }
        }
        .glassCard()
    }

    private func isSelected(_ lang: AppLanguage) -> Bool {
        LanguageManager.shared.selected == lang
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appState.birthDataStore.savedData != nil {
                settingsRow(icon: "arrow.triangle.2.circlepath", title: "Haritayı Yeniden Hesapla") {
                    Task { await appState.restoreSavedChart() }
                }
                Divider().overlay(AstroTheme.cardBorder)
            }
            NavigationLink {
                PeopleListView()
                    .environment(appState)
                    .environment(appState.store)
                    .environment(appState.entitlements)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.3")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.accent)
                        .frame(width: 24)
                    Text("Kişiler")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(appState.birthDataStore.people.count)")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            Divider().overlay(AstroTheme.cardBorder)
            settingsRow(icon: "arrow.clockwise", title: "Satın Almaları Geri Yükle") {
                Task { await appState.store.restorePurchases() }
            }
            Divider().overlay(AstroTheme.cardBorder)
            settingsRow(icon: "info.circle", title: "Hakkında") {
                showAbout = true
            }
            Divider().overlay(AstroTheme.cardBorder)
            settingsRow(icon: "doc.text", title: "Gizlilik Politikası") {}
        }
        .glassCard(padding: 0)
    }

    // MARK: - Admin Panel

    private var adminCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundStyle(AstroTheme.planet(.sun))
                Text("Admin")
                    .font(.headline)
                    .foregroundStyle(AstroTheme.planet(.sun))
            }

            Toggle(isOn: $adminTestMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kullanıcı Modu")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Text(adminTestMode
                         ? "Normal kullanıcı gibi görüyorsun (ödeme/reklam aktif)"
                         : "Admin — tüm özellikler açık")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
            }
            .tint(AstroTheme.planet(.sun))
            .onChange(of: adminTestMode) { _, newValue in
                EntitlementManager.adminTestMode = newValue
            }

            // Kredi bilgisi
            HStack {
                Text("Harita Kredisi:")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                Spacer()
                Text("\(appState.store.chartCredits)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
        }
        .glassCard()
    }

    // MARK: - Disclaimer

    private var disclaimerCard: some View {
        VStack(spacing: 8) {
            Text("Bu uygulama eğlence amaçlıdır.")
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
            Text("Profesyonel danışmanlık yerine geçmez. Astrolojik yorumlar kişisel gelişim ve eğlence için sunulmaktadır.")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Yasal uyarı: Bu uygulama eğlence amaçlıdır, profesyonel danışmanlık yerine geçmez.")
        .onTapGesture(count: 5) {
            showDeviceID = true
        }
        .alert("Cihaz ID", isPresented: $showDeviceID) {
            Button("Kopyala") {
                UIPasteboard.general.string = UIDevice.current.identifierForVendor?.uuidString ?? "Bilinmiyor"
            }
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(UIDevice.current.identifierForVendor?.uuidString ?? "Bilinmiyor")
        }
    }

    // MARK: - Row

    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.accent)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .accessibilityLabel(title)
    }
}
