import Foundation

/// Tek tek (izole) açı yorumlarını **bütüncül** bir okumaya dönüştürür.
///
/// Sorun: her açı yorumu kendi başına doğru ama liste halinde gelişigüzel
/// dizildiğinde pozitif bir satırın altına negatif bir satır gelir →
/// tutarsızlık hissi. Çözüm çelişkiyi *yok etmek* değil (o aldatıcı olur),
/// onu **düzenlemek ve çerçevelemek**: ağırlığa göre sırala, tona göre grupla,
/// üstte hesaplanan bir özet ver ve klasik konfigürasyonları (Stellium, T-Kare,
/// Büyük Üçgen, odak gezegen) tespit et.
///
/// Tüm yorum motorları `DailyCosmicCoach.GuidanceItem` üretir; bu motor o ortak
/// para birimi üzerinde çalışır, dolayısıyla composite/synastry/birth/solar
/// hepsinde yeniden kullanılabilir.
struct ChartSynthesizer: Sendable {

    enum Context: Sendable {
        case composite, synastry, birthChart, solarReturn

        /// Özet cümlesinin öznesi
        var subject: String {
            switch self {
            case .composite:   "İlişkinizde"
            case .synastry:    "Aranızda"
            case .birthChart:  "Haritanızda"
            case .solarReturn: "Bu yıl"
            }
        }
    }

    enum Balance: Sendable { case harmonious, balanced, challenging }

    // MARK: - Girdi / Çıktı modelleri

    /// Sentez girdisi: bir yorum + önem ağırlığı + içerdiği gezegenler.
    struct WeightedGuidance: Sendable {
        let item: DailyCosmicCoach.GuidanceItem
        let weight: Double        // sıralama + özet için
        let planets: [Planet]     // baskın tema tespiti için (ASC/MC hariç)
    }

    /// Pattern tespiti için tek-harita yapısı (synastry'de nil geçilir).
    struct ChartStructure: Sendable {
        let planets: [PlanetPosition]
        let aspects: [Aspect]     // major filtrelenmemiş; motor içinde süzülür
    }

    struct ToneGroup: Identifiable, Sendable {
        let id = UUID()
        let tone: DailyCosmicCoach.Tone
        let title: String
        let items: [DailyCosmicCoach.GuidanceItem]
    }

    struct Synthesis: Sendable {
        let summary: DailyCosmicCoach.GuidanceItem
        let balance: Balance
        let patterns: [DailyCosmicCoach.GuidanceItem]
        let groups: [ToneGroup]

        var hasContent: Bool { !groups.isEmpty }
    }

    // MARK: - Ağırlık (paylaşılan kanonik tablo)

    /// Bir açının önem ağırlığı: gezegen ağırlıkları × açı yakınlığı (dar orb).
    /// Çağrı noktaları bunu kullanır ki ağırlık mantığı tek yerde kalsın.
    static func weight(_ aspect: Aspect) -> Double {
        (pointWeight(aspect.point1) + pointWeight(aspect.point2)) / (aspect.orb + 0.5)
    }

    static func pointWeight(_ point: ChartPoint) -> Double {
        switch point {
        case .planet(let p):       planetWeight(p)
        case .ascendant, .midheaven: 4
        }
    }

    private static func planetWeight(_ p: Planet) -> Double {
        switch p {
        case .sun, .moon:              5
        case .mercury, .venus, .mars:  4
        case .jupiter, .saturn:        3
        case .uranus, .neptune, .pluto: 2
        default:                       1
        }
    }

    /// Açının içerdiği gezegenler (ASC/MC gibi açısal noktalar hariç).
    static func planets(in aspect: Aspect) -> [Planet] {
        [aspect.point1, aspect.point2].compactMap {
            if case .planet(let p) = $0 { return p }
            return nil
        }
    }

    // MARK: - Ana giriş

    static func synthesize(
        _ guidances: [WeightedGuidance],
        structure: ChartStructure?,
        context: Context
    ) -> Synthesis {

        // ── Katman 1: sırala + grupla ──
        let sorted = guidances.sorted { $0.weight > $1.weight }
        let groups = buildGroups(sorted)

        // ── Katman 3: pattern tespiti ──
        let patterns = structure.map { detectPatterns($0) } ?? []

        // ── Katman 2: hesaplanan özet ──
        let (summary, balance) = buildSummary(sorted, context: context)

        return Synthesis(summary: summary, balance: balance, patterns: patterns, groups: groups)
    }

    // MARK: - Katman 1: Gruplama

    private static func buildGroups(_ sorted: [WeightedGuidance]) -> [ToneGroup] {
        let order: [(DailyCosmicCoach.Tone, String)] = [
            (.harmonik,  "Güçlü Yanlar"),
            (.zorlayici, "Zorlayıcı Alanlar"),
            (.notr,      "Belirgin Temalar")
        ]
        return order.compactMap { tone, title in
            let items = sorted.filter { $0.item.tone == tone }.map { $0.item }
            guard !items.isEmpty else { return nil }
            return ToneGroup(tone: tone, title: title, items: items)
        }
    }

    // MARK: - Katman 2: Özet

    private static func buildSummary(
        _ sorted: [WeightedGuidance],
        context: Context
    ) -> (DailyCosmicCoach.GuidanceItem, Balance) {

        let harmonikW  = sorted.filter { $0.item.tone == .harmonik }.reduce(0) { $0 + $1.weight }
        let zorlayiciW = sorted.filter { $0.item.tone == .zorlayici }.reduce(0) { $0 + $1.weight }

        // Denge
        let balance: Balance
        if harmonikW >= zorlayiciW * 1.5 {
            balance = .harmonious
        } else if zorlayiciW >= harmonikW * 1.5 {
            balance = .challenging
        } else {
            balance = .balanced
        }

        let balancePhrase: String
        switch balance {
        case .harmonious:  balancePhrase = "uyum ve akış ağır basıyor"
        case .balanced:    balancePhrase = "uyum ve gerilim dengeli biçimde bir arada"
        case .challenging: balancePhrase = "zorlayıcı dinamikler ve gerilim belirgin"
        }

        var sentences: [String] = ["\(context.subject) \(balancePhrase)."]

        // En belirgin tema (en yüksek ağırlıklı yorum)
        if let top = sorted.first {
            sentences.append("En belirgin tema: \(top.item.title).")
        }

        // Baskın gezegen (yorumlarda en sık geçen)
        if let dominant = dominantPlanet(sorted) {
            let theme = ChartAspectInterpreter.planetTheme[dominant] ?? "bu tema"
            sentences.append("En çok öne çıkan gezegen \(dominant.name) — \(theme).")
        }

        // Çelişki isimlendirme: hem güçlü uyum hem güçlü gerilim varsa açıkça söyle
        let maxW = max(harmonikW, zorlayiciW)
        let minW = min(harmonikW, zorlayiciW)
        if maxW > 0, minW / maxW >= 0.45 {
            sentences.append("Hem güçlü uyum hem de üzerinde çalışılması gereken gerilimler bir arada; bu, hem rahat ettiğiniz hem de bilinçli çaba isteyen bir yapı.")
        }

        let toneForBalance: DailyCosmicCoach.Tone
        switch balance {
        case .harmonious:  toneForBalance = .harmonik
        case .balanced:    toneForBalance = .notr
        case .challenging: toneForBalance = .zorlayici
        }

        let summary = DailyCosmicCoach.GuidanceItem(
            icon: "sparkles",
            title: "Genel Değerlendirme",
            message: sentences.joined(separator: " "),
            tone: toneForBalance
        )
        return (summary, balance)
    }

    private static func dominantPlanet(_ sorted: [WeightedGuidance]) -> Planet? {
        var counts: [Planet: Int] = [:]
        for g in sorted {
            for p in g.planets { counts[p, default: 0] += 1 }
        }
        // En sık geçen; en az 2 kez görünmeli ki "tekrarlayan" sayılsın
        guard let best = counts.max(by: { $0.value < $1.value }), best.value >= 2 else { return nil }
        return best.key
    }

    // MARK: - Katman 3: Pattern tespiti

    private static let mainPlanets: [Planet] =
        [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]

    private static func detectPatterns(_ structure: ChartStructure) -> [DailyCosmicCoach.GuidanceItem] {
        var items: [DailyCosmicCoach.GuidanceItem] = []
        let majors = structure.aspects.filter { $0.type.isMajor }

        items.append(contentsOf: detectStelliums(structure.planets))
        items.append(contentsOf: detectTSquares(majors))
        items.append(contentsOf: detectGrandTrines(majors))
        items.append(contentsOf: detectFocalPlanets(majors))

        return items
    }

    // Stellium: aynı burçta veya aynı evde 3+ ana gezegen
    private static func detectStelliums(_ positions: [PlanetPosition]) -> [DailyCosmicCoach.GuidanceItem] {
        let mains = positions.filter { mainPlanets.contains($0.planet) }
        var items: [DailyCosmicCoach.GuidanceItem] = []
        var seenSets: [Set<Planet>] = []

        // Burç bazlı
        let bySign = Dictionary(grouping: mains, by: { $0.sign })
        for (sign, group) in bySign where group.count >= 3 {
            let planetSet = Set(group.map { $0.planet })
            seenSets.append(planetSet)
            let names = group.map { $0.planet.name }.joined(separator: ", ")
            items.append(DailyCosmicCoach.GuidanceItem(
                icon: "circle.grid.3x3.fill",
                title: "Stellium · \(sign.name)",
                message: "\(sign.name) burcunda yoğunlaşma: \(names). Bu burcun temaları haritada belirgin biçimde öne çıkıyor; enerji burada toplanmış.",
                tone: .notr
            ))
        }

        // Ev bazlı (burç stelliumuyla aynı gezegen kümesiyse atla)
        let byHouse = Dictionary(grouping: mains, by: { $0.house })
        for (house, group) in byHouse where group.count >= 3 {
            let planetSet = Set(group.map { $0.planet })
            if seenSets.contains(planetSet) { continue }
            let names = group.map { $0.planet.name }.joined(separator: ", ")
            items.append(DailyCosmicCoach.GuidanceItem(
                icon: "circle.grid.3x3.fill",
                title: "Stellium · \(house). ev",
                message: "\(house). evde yoğunlaşma: \(names). Bu yaşam alanı haritada özellikle vurgulu ve baskın.",
                tone: .notr
            ))
        }
        return items
    }

    // T-Kare: karşıt çift + her ikisine kare yapan apex
    private static func detectTSquares(_ majors: [Aspect]) -> [DailyCosmicCoach.GuidanceItem] {
        let present = aspectIndex(majors)
        let points = participatingPoints(majors)
        var items: [DailyCosmicCoach.GuidanceItem] = []
        var seen: Set<String> = []

        for opp in majors where opp.type == .opposition {
            let a = opp.point1, b = opp.point2
            for c in points where c != a && c != b {
                if has(present, c, a, .square) && has(present, c, b, .square) {
                    let key = ([a.shortName, b.shortName].sorted().joined() + "|" + c.shortName)
                    if seen.contains(key) { continue }
                    seen.insert(key)
                    items.append(DailyCosmicCoach.GuidanceItem(
                        icon: "triangle.fill",
                        title: "T-Kare · \(c.name)",
                        message: "\(c.name) odağında bir gerilim üçgeni (\(a.name) ile \(b.name) karşıtlığı). Sürekli harekete geçiren, dinamik ama zorlayıcı bir kalıp; \(c.name) temasında bilinçli çaba ve denge ister.",
                        tone: .zorlayici
                    ))
                }
            }
        }
        return items
    }

    // Büyük Üçgen: karşılıklı üçgen yapan üçlü
    private static func detectGrandTrines(_ majors: [Aspect]) -> [DailyCosmicCoach.GuidanceItem] {
        let present = aspectIndex(majors)
        let points = participatingPoints(majors)
        var items: [DailyCosmicCoach.GuidanceItem] = []
        var seen: Set<String> = []

        for i in points.indices {
            for j in points.indices where j > i {
                for k in points.indices where k > j {
                    let a = points[i], b = points[j], c = points[k]
                    if has(present, a, b, .trine) && has(present, b, c, .trine) && has(present, a, c, .trine) {
                        let key = [a.shortName, b.shortName, c.shortName].sorted().joined()
                        if seen.contains(key) { continue }
                        seen.insert(key)
                        let names = [a.name, b.name, c.name].joined(separator: ", ")
                        items.append(DailyCosmicCoach.GuidanceItem(
                            icon: "triangle",
                            title: "Büyük Üçgen",
                            message: "\(names) arasında karşılıklı uyum. Doğal yetenek ve akış sağlar; emek vermeden gelen bir kolaylık ve denge alanı.",
                            tone: .harmonik
                        ))
                    }
                }
            }
        }
        return items
    }

    // Odak gezegen: major açılarda 3+ kez geçen gezegen (tekrarlayan tema)
    private static func detectFocalPlanets(_ majors: [Aspect]) -> [DailyCosmicCoach.GuidanceItem] {
        var counts: [Planet: Int] = [:]
        for asp in majors {
            for p in planets(in: asp) where mainPlanets.contains(p) {
                counts[p, default: 0] += 1
            }
        }
        let focal = counts.filter { $0.value >= 3 }.sorted { $0.value > $1.value }.prefix(2)
        return focal.map { planet, count in
            let theme = ChartAspectInterpreter.planetTheme[planet] ?? "bu tema"
            return DailyCosmicCoach.GuidanceItem(
                icon: "scope",
                title: "\(planet.name) Odakta",
                message: "\(planet.name) (\(theme)) haritada tekrar tekrar — \(count) ayrı majör açıda — vurgulanıyor; baskın bir motif olarak öne çıkıyor.",
                tone: .notr
            )
        }
    }

    // MARK: - Pattern yardımcıları

    /// Major açıları "tip → {nokta-çifti anahtarı}" dizinine çevirir.
    private static func aspectIndex(_ majors: [Aspect]) -> [AspectType: Set<String>] {
        var index: [AspectType: Set<String>] = [:]
        for asp in majors {
            index[asp.type, default: []].insert(pairKey(asp.point1, asp.point2))
        }
        return index
    }

    private static func pairKey(_ a: ChartPoint, _ b: ChartPoint) -> String {
        let pair = [a.shortName, b.shortName].sorted()
        return "\(pair[0])|\(pair[1])"
    }

    private static func has(_ index: [AspectType: Set<String>], _ a: ChartPoint, _ b: ChartPoint, _ type: AspectType) -> Bool {
        index[type]?.contains(pairKey(a, b)) ?? false
    }

    private static func participatingPoints(_ majors: [Aspect]) -> [ChartPoint] {
        var set: [ChartPoint] = []
        for asp in majors {
            if !set.contains(asp.point1) { set.append(asp.point1) }
            if !set.contains(asp.point2) { set.append(asp.point2) }
        }
        return set
    }
}
