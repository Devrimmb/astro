import SwiftUI

// MARK: - Günlük hak

/// Her kart falı için günde bir ücretsiz çekim. Anahtar `UserDefaults`'ta son
/// kullanım tarihini tutar; eski anahtarlar korunur (katina_…, rune_…).
struct DailyReadingQuota {
    let key: String

    var hasFreeReadingToday: Bool {
        guard let last = UserDefaults.standard.object(forKey: key) as? Date else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    func consume() {
        UserDefaults.standard.set(Date(), forKey: key)
    }
}

// MARK: - Ortak kart falı akışı

/// Dört kart falının (Tarot, Katina, Rün, Tanrı kartı) paylaştığı ekran:
/// günlük hak / reklam kapısı → deste çarkı → seçilen kartın yorum paneli.
///
/// Desteye özgü olan yalnızca: kart tipi, `DeckStyle`, ön yüz çizimi, yorum metni
/// ve paylaşım. Tarot ayrıca kategori rozeti (`badge`) ve kendi "tekrar" davranışını
/// (`onAgain`: kategori seçimine dön) verir.
struct DeckReadingFlow<Card, Front: View>: View {
    struct Config {
        var title: String                  // reklam kapısı başlığı ("Katina Falı")
        var glyph: String                  // kapı sembolü
        var adDescription: String          // "Kartını tekrar çekmek için kısa bir reklam izle."
        var subtitle = "Zihnini sorunda tut, desteyi masaya ser"
        var readingTitle = "Kartın Yorumu"
        var quotaKey: String
        var style: DeckStyle
    }

    @Environment(EntitlementManager.self) private var entitlements

    let config: Config
    let deck: [Card]
    let cardName: (Card) -> String
    let front: (Card, CGSize) -> Front
    let interpretation: (Card) -> String
    var share: ((Card) -> Void)? = nil
    var badge: Pill? = nil
    var onAgain: (() -> Void)? = nil

    @State private var isUnlockedByAd = false
    @State private var run = 0

    init(config: Config,
         deck: [Card],
         cardName: @escaping (Card) -> String,
         @ViewBuilder front: @escaping (Card, CGSize) -> Front,
         interpretation: @escaping (Card) -> String,
         share: ((Card) -> Void)? = nil,
         badge: Pill? = nil,
         onAgain: (() -> Void)? = nil) {
        self.config = config
        self.deck = deck
        self.cardName = cardName
        self.front = front
        self.interpretation = interpretation
        self.share = share
        self.badge = badge
        self.onAgain = onAgain
    }

    private var quota: DailyReadingQuota { DailyReadingQuota(key: config.quotaKey) }

    private var canDraw: Bool {
        entitlements.hasNatalChart || quota.hasFreeReadingToday || isUnlockedByAd
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            if canDraw {
                wheel
                    .id(run)
                    .transition(.opacity)
            } else {
                ScrollView {
                    adGate
                        .padding()
                        .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isUnlockedByAd)
    }

    // MARK: Reklam kapısı

    private var adGate: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Text(config.glyph)
                .font(.system(size: 48))
                .foregroundStyle(config.style.tint)

            VStack(spacing: 8) {
                Text(config.title)
                    .font(.largeTitle)
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                Text("Bugünkü ücretsiz hakkını kullandın")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            AdGateView(title: "Tekrar Fal Bak", description: config.adDescription) {
                isUnlockedByAd = true
            }
        }
    }

    // MARK: Çark

    private var wheel: some View {
        DeckWheelView(
            deck: deck,
            style: config.style,
            subtitle: config.subtitle,
            cardName: cardName,
            front: front,
            panel: { picks, _ in panel(picks) },
            onReveal: { _ in quota.consume() }
        )
        .overlay(alignment: .top) {
            if let badge {
                badge
                    .scaleEffect(1.25)
                    .padding(.top, 12)
            }
        }
    }

    // MARK: Okuma paneli

    @ViewBuilder
    private func panel(_ picks: [DeckPick<Card>]) -> some View {
        if let pick = picks.first {
            let card = pick.card
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(cardName(card))
                        .font(.title2)
                        .fontDesign(.serif)
                        .foregroundStyle(AstroTheme.gold)
                    Spacer()
                    if let badge { badge }
                }

                Rectangle()
                    .fill(config.style.tint.opacity(0.24))
                    .frame(height: 1)

                Text(config.readingTitle)
                    .font(.headline)
                    .foregroundStyle(.white)

                MarkdownTextView(interpretation(card))

                HStack(spacing: 12) {
                    if let share {
                        Button {
                            share(card)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Paylaş")
                            }
                            .glassButton()
                        }
                    }

                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            isUnlockedByAd = false
                            if let onAgain { onAgain() } else { run += 1 }
                        }
                    } label: {
                        Label("Tekrar Kart Çek", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AstroTheme.textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(AstroTheme.surface, in: .capsule)
                            .overlay { Capsule().stroke(AstroTheme.cardBorder, lineWidth: 1) }
                    }
                }
                .padding(.top, 6)
            }
        }
    }
}
