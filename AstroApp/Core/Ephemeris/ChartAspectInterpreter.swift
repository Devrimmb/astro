import Foundation

/// Harita-içi açıları (bir haritanın kendi noktaları arasındaki `Aspect`)
/// kanonik olarak yorumlar. Solar Return ve Composite gibi, transit/synastry
/// gibi iki-taraflı olmayan ama natal "doğuştan" da olmayan haritalar için.
///
/// `DailyCosmicCoach` ile aynı yaklaşım: her noktanın temel teması + açı
/// doğası, bağlama özel çerçeveyle ("bu yıl" / "ilişkinizde") birleştirilir.
struct ChartAspectInterpreter: Sendable {

    enum Context: Sendable {
        case solarReturn  // yıllık harita
        case composite    // ilişki haritası

        var opener: String {
            switch self {
            case .solarReturn: "Bu yıl"
            case .composite: "İlişkinizde"
            }
        }
    }

    static func interpretation(_ aspect: Aspect, context: Context) -> DailyCosmicCoach.GuidanceItem {
        let t1 = theme(for: aspect.point1)
        let t2 = theme(for: aspect.point2)

        let clauseBody: String
        let tone: DailyCosmicCoach.Tone
        let icon: String
        switch aspect.type.nature {
        case .harmonik:
            clauseBody = "uyumlu bir akış var; bu iki alan birbirini destekliyor."
            tone = .harmonik
            icon = "checkmark.seal.fill"
        case .zorlayici:
            clauseBody = "gerilim var; bu iki alan denge ve bilinçli çaba istiyor."
            tone = .zorlayici
            icon = "exclamationmark.triangle.fill"
        case .notr:
            clauseBody = "güçlü bir birleşme var; bu temalar belirgin biçimde öne çıkıyor."
            tone = .notr
            icon = "circle.hexagonpath.fill"
        }

        let message = "\(context.opener), \(t1) ile \(t2) arasında \(clauseBody)"
        let title = "\(aspect.point1.name) \(aspect.type.turkishName) \(aspect.point2.name)"
        let glyphs = "\(aspect.point1.glyph) \(aspect.type.symbol) \(aspect.point2.glyph)"

        return DailyCosmicCoach.GuidanceItem(icon: icon, title: title, message: message, tone: tone, glyphs: glyphs)
    }

    private static func theme(for point: ChartPoint) -> String {
        switch point {
        case .planet(let p): planetTheme[p] ?? "kişilik ifadesi"
        case .ascendant: "dış görünüş ve hayata yaklaşım"
        case .midheaven: "kariyer ve yaşam hedefleri"
        }
    }

    /// Gezegenin temel (harita-içi) kanonik teması.
    /// `ChartSynthesizer` özet üretiminde de okur (internal görünürlük).
    static let planetTheme: [Planet: String] = [
        .sun: "kimlik ve irade",
        .moon: "duygular ve ihtiyaçlar",
        .mercury: "iletişim ve düşünce",
        .venus: "sevgi ve uyum",
        .mars: "eylem ve enerji",
        .jupiter: "büyüme ve fırsat",
        .saturn: "sorumluluk ve disiplin",
        .uranus: "değişim ve özgürlük",
        .neptune: "hayal ve sezgi",
        .pluto: "dönüşüm ve güç",
        .northNode: "yaşam yönü ve kader ekseni",
        .chiron: "yaralar ve şifa"
    ]
}
