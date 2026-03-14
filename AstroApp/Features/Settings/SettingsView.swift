import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var showPaywall = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        proStatusCard
                        languageCard
                        settingsCard
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
            NavigationLink {
                ProfileView()
                    .environment(appState)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.accent)
                        .frame(width: 24)
                    Text("Profilim")
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
            Divider().overlay(AstroTheme.cardBorder)
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
