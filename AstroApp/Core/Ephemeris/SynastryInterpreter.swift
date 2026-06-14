import Foundation

/// İki kişinin haritası arasındaki synastry (ilişki) açılarını kanonik olarak
/// yorumlar. `DailyCosmicCoach` ile aynı yaklaşım: sabit/yerleşik astrolojik
/// anlamları kompozisyonel birleştirir — uydurma yok.
///
/// Transit'ten farkı: burada iki taraf da bir kişinin gezegeni (eşit roller),
/// "yaşam alanı" değil. Bu yüzden her gezegenin *ilişkideki teması* + açının
/// doğası birleştirilir, "aranızda" bağlamıyla.
struct SynastryInterpreter: Sendable {

    static func interpretation(
        _ a: SynastryAspect,
        name1: String,
        name2: String
    ) -> DailyCosmicCoach.GuidanceItem {
        let t1 = relationshipTheme[a.planet1] ?? "kişilik ifadesi"
        let t2 = relationshipTheme[a.planet2] ?? "kişilik ifadesi"

        let clause: String
        let tone: DailyCosmicCoach.Tone
        let icon: String
        switch a.type.nature {
        case .harmonik:
            clause = "uyumlu ve destekleyici biçimde akıyor; ilişkide doğal bir uyum kaynağı."
            tone = .harmonik
            icon = "checkmark.seal.fill"
        case .zorlayici:
            clause = "güçlü bir çekim yaratıyor ama sürtüşme ve gerilim de getirebilir; farkındalıkla büyüme fırsatına dönüşür."
            tone = .zorlayici
            icon = "exclamationmark.triangle.fill"
        case .notr:
            clause = "yoğun biçimde birleşiyor; bu tema ilişkide çok belirgin ve baskın."
            tone = .notr
            icon = "circle.hexagonpath.fill"
        }

        let n1 = name1.isEmpty ? "1. kişi" : name1
        let n2 = name2.isEmpty ? "2. kişi" : name2
        let message = "\(n1) ve \(n2) arasında \(t1) ile \(t2) \(clause)"
        let title = "\(a.planet1.name) \(a.type.turkishName) \(a.planet2.name)"
        let glyphs = "\(ChartPoint.planet(a.planet1).glyph) \(a.type.symbol) \(ChartPoint.planet(a.planet2).glyph)"

        return DailyCosmicCoach.GuidanceItem(
            icon: icon,
            title: title,
            message: message,
            tone: tone,
            glyphs: glyphs
        )
    }

    /// Gezegenin ilişki bağlamındaki kanonik teması (cümle ortasında akacak)
    private static let relationshipTheme: [Planet: String] = [
        .sun: "kimlik ve ego ifadesi",
        .moon: "duygusal ihtiyaçlar ve yakınlık",
        .mercury: "iletişim ve fikir alışverişi",
        .venus: "sevgi, çekim ve zevkler",
        .mars: "tutku, arzu ve enerji",
        .jupiter: "büyüme, iyimserlik ve özgürlük arzusu",
        .saturn: "bağlılık, sorumluluk ve istikrar",
        .uranus: "heyecan, özgürlük ve beklenmediklik",
        .neptune: "romantik idealler ve ruhsal bağ",
        .pluto: "yoğunluk, güç ve dönüşüm"
    ]
}
