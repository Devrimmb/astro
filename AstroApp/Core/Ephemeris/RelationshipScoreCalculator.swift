import Foundation

/// Ciro Discepolo metodu ile iliski skoru hesaplama
/// Referans: Kerykeion RelationshipScoreFactory
struct RelationshipScoreCalculator: Sendable {

    // MARK: - Sabitler

    /// Ayni modalite (Oncü/Sabit/Degisken) paylasimi
    private static let destinySignPoints = 5

    /// Gunes-Gunes veya Gunes-Ay major aspect (conjunction/opposition/square)
    /// Orb <= 2° ise yüksek hassasiyet puani
    private static let majorAspectPointsHighPrecision = 11
    /// Orb > 2° ise standart puan
    private static let majorAspectPointsStandard = 8
    /// Yuksek hassasiyet esigi
    private static let highPrecisionOrbThreshold: Double = 2.0

    /// Diger aspect'ler icin puan (sextile, trine)
    private static let minorAspectPoints = 4

    /// Gunes-Ascendant aspect puani
    private static let sunAscendantPoints = 4
    /// Ay-Ascendant aspect puani
    private static let moonAscendantPoints = 4
    /// Venus-Mars aspect puani
    private static let venusPoints = 4

    // MARK: - Skor Araliklari

    enum ScoreDescription: String, Sendable {
        case minimal = "Minimal"
        case medium = "Orta Düzey"
        case important = "Önemli"
        case veryImportant = "Çok Önemli"
        case exceptional = "Olağanüstü"
        case rareExceptional = "Nadir Olağanüstü"

        var turkishDescription: String {
            switch self {
            case .minimal:
                "Bu iki harita arasında belirgin bir astrolojik bağ zayıf. Ancak astroloji her şey değildir — kişisel çaba ve iletişim her ilişkiyi güçlendirebilir."
            case .medium:
                "Orta düzeyde bir astrolojik bağ var. Bazı gezegen etkileşimleri dikkat çekici. İlişkide bilinçli çaba ile güzel bir uyum yakalanabilir."
            case .important:
                "Önemli bir astrolojik bağ mevcut. Gezegenler arasında anlamlı etkileşimler var ve bu iki kişi birbirini doğal olarak etkiliyor."
            case .veryImportant:
                "Çok güçlü bir astrolojik bağ! Gezegenler arasındaki etkileşimler yoğun ve derin. Bu ilişki her iki kişi için de dönüştürücü olabilir."
            case .exceptional:
                "Olağanüstü bir astrolojik uyum! Bu derece güçlü bağlar nadiren görülür. Gezegenler adeta birbirine kilitlenmiş durumda."
            case .rareExceptional:
                "Son derece nadir bir astrolojik bağ! Bu düzeyde etkileşim çok az çiftte görülür. Karmik ve derin bir bağlantı söz konusu."
            }
        }
    }

    // MARK: - Sonuç Modeli

    struct ScoreBreakdown: Identifiable, Sendable {
        let id = UUID()
        let rule: String
        let description: String
        let points: Int
        let details: String
    }

    struct RelationshipScore: Sendable {
        let scoreValue: Int
        let scoreDescription: ScoreDescription
        let isDestinySign: Bool
        let breakdown: [ScoreBreakdown]

        /// 0-100 arasinda normalize edilmis skor (UI icin)
        var normalizedScore: Int {
            // Discepolo skoru genelde 0-40 arasinda, bunu 0-100'e cevirelim
            // 30+ = 100, 0 = 15 (minimum gosterim)
            let normalized = Double(scoreValue) / 30.0 * 100.0
            return max(15, min(100, Int(normalized)))
        }
    }

    // MARK: - Hesaplama

    /// Iki harita arasindaki Discepolo iliski skorunu hesapla
    static func calculate(
        chart1: BirthChart,
        chart2: BirthChart,
        crossAspects: [SynastryAspect]
    ) -> RelationshipScore {
        var scoreValue = 0
        var breakdown: [ScoreBreakdown] = []
        var isDestinySign = false

        // 1. Destiny Sign — ayni modalite kontrolu
        if let sun1 = chart1.sunSign, let sun2 = chart2.sunSign {
            if sun1.modality == sun2.modality {
                isDestinySign = true
                scoreValue += destinySignPoints
                breakdown.append(ScoreBreakdown(
                    rule: "destiny_sign",
                    description: "Aynı modalite (\(sun1.modality.displayName))",
                    points: destinySignPoints,
                    details: "\(sun1.name) & \(sun2.name)"
                ))
            }
        }

        // 2. Her cross-aspect icin puanlama
        for aspect in crossAspects {
            // Gunes-Gunes major aspect (conjunction, opposition, square)
            if let points = evaluateSunSunMajor(aspect) {
                scoreValue += points.points
                breakdown.append(points)
            }

            // Gunes-Gunes diger aspect'ler (sextile, trine)
            if let points = evaluateSunSunOther(aspect) {
                scoreValue += points.points
                breakdown.append(points)
            }

            // Gunes-Ay conjunction
            if let points = evaluateSunMoonConjunction(aspect) {
                scoreValue += points.points
                breakdown.append(points)
            }

            // Gunes-Ay diger aspect'ler
            if let points = evaluateSunMoonOther(aspect) {
                scoreValue += points.points
                breakdown.append(points)
            }

            // Venus-Mars herhangi bir aspect
            if let points = evaluateVenusMars(aspect) {
                scoreValue += points.points
                breakdown.append(points)
            }
        }

        // 3. Ascendant aspect'leri (houses verisinden)
        let asc1Longitude = chart1.houses.first(where: { $0.id == 1 })?.cusp
        let asc2Longitude = chart2.houses.first(where: { $0.id == 1 })?.cusp

        // Chart1'in gezegenleri vs Chart2'nin Ascendant'i
        if let asc2 = asc2Longitude {
            for planet in chart1.planets {
                if let points = evaluatePlanetAscendant(
                    planet: planet, ascendantLongitude: asc2, chartOwner: "2"
                ) {
                    scoreValue += points.points
                    breakdown.append(points)
                }
            }
        }

        // Chart2'nin gezegenleri vs Chart1'in Ascendant'i
        if let asc1 = asc1Longitude {
            for planet in chart2.planets {
                if let points = evaluatePlanetAscendant(
                    planet: planet, ascendantLongitude: asc1, chartOwner: "1"
                ) {
                    scoreValue += points.points
                    breakdown.append(points)
                }
            }
        }

        // 4. Skor aciklamasini belirle
        let description = scoreDescription(for: scoreValue)

        return RelationshipScore(
            scoreValue: scoreValue,
            scoreDescription: description,
            isDestinySign: isDestinySign,
            breakdown: breakdown.sorted { $0.points > $1.points }
        )
    }

    // MARK: - Aspect Degerlendirme Fonksiyonlari

    /// Gunes-Gunes: conjunction, opposition, square
    private static func evaluateSunSunMajor(_ aspect: SynastryAspect) -> ScoreBreakdown? {
        guard aspect.planet1 == .sun && aspect.planet2 == .sun else { return nil }
        guard [.conjunction, .opposition, .square].contains(aspect.type) else { return nil }

        let isHighPrecision = aspect.orb <= highPrecisionOrbThreshold
        let points = isHighPrecision ? majorAspectPointsHighPrecision : majorAspectPointsStandard
        let precision = isHighPrecision ? "hassas (≤2°)" : "standart"

        return ScoreBreakdown(
            rule: "sun_sun_major",
            description: "Güneş–Güneş \(aspect.type.turkishName) (\(precision))",
            points: points,
            details: "\(String(format: "%.1f", aspect.orb))° orb"
        )
    }

    /// Gunes-Gunes: sextile, trine
    private static func evaluateSunSunOther(_ aspect: SynastryAspect) -> ScoreBreakdown? {
        guard aspect.planet1 == .sun && aspect.planet2 == .sun else { return nil }
        guard ![.conjunction, .opposition, .square].contains(aspect.type) else { return nil }

        return ScoreBreakdown(
            rule: "sun_sun_minor",
            description: "Güneş–Güneş \(aspect.type.turkishName)",
            points: minorAspectPoints,
            details: "\(String(format: "%.1f", aspect.orb))° orb"
        )
    }

    /// Gunes-Ay conjunction
    private static func evaluateSunMoonConjunction(_ aspect: SynastryAspect) -> ScoreBreakdown? {
        let pair: Set<Planet> = [aspect.planet1, aspect.planet2]
        guard pair == [.sun, .moon] else { return nil }
        guard aspect.type == .conjunction else { return nil }

        let isHighPrecision = aspect.orb <= highPrecisionOrbThreshold
        let points = isHighPrecision ? majorAspectPointsHighPrecision : majorAspectPointsStandard
        let precision = isHighPrecision ? "hassas (≤2°)" : "standart"

        return ScoreBreakdown(
            rule: "sun_moon_conjunction",
            description: "Güneş–Ay Kavuşum (\(precision))",
            points: points,
            details: "\(String(format: "%.1f", aspect.orb))° orb"
        )
    }

    /// Gunes-Ay diger aspect'ler
    private static func evaluateSunMoonOther(_ aspect: SynastryAspect) -> ScoreBreakdown? {
        let pair: Set<Planet> = [aspect.planet1, aspect.planet2]
        guard pair == [.sun, .moon] else { return nil }
        guard aspect.type != .conjunction else { return nil }

        return ScoreBreakdown(
            rule: "sun_moon_other",
            description: "Güneş–Ay \(aspect.type.turkishName)",
            points: minorAspectPoints,
            details: "\(String(format: "%.1f", aspect.orb))° orb"
        )
    }

    /// Venus-Mars herhangi bir aspect
    private static func evaluateVenusMars(_ aspect: SynastryAspect) -> ScoreBreakdown? {
        let pair: Set<Planet> = [aspect.planet1, aspect.planet2]
        guard pair == [.venus, .mars] else { return nil }

        return ScoreBreakdown(
            rule: "venus_mars",
            description: "Venüs–Mars \(aspect.type.turkishName)",
            points: venusPoints,
            details: "\(String(format: "%.1f", aspect.orb))° orb"
        )
    }

    /// Gunes/Ay - Ascendant aspect kontrolu
    private static func evaluatePlanetAscendant(
        planet: PlanetPosition,
        ascendantLongitude: Double,
        chartOwner: String
    ) -> ScoreBreakdown? {
        // Sadece Gunes ve Ay icin kontrol
        guard planet.planet == .sun || planet.planet == .moon else { return nil }

        var diff = abs(planet.longitude - ascendantLongitude)
        if diff > 180 { diff = 360 - diff }

        // Major aspect kontrolu
        for aspectType in AspectType.allCases {
            let orb = abs(diff - aspectType.rawValue)
            // Ascendant icin daha dar orb kullan (6°)
            let maxOrb = min(aspectType.orb, 6.0)
            if orb <= maxOrb {
                let points = planet.planet == .sun ? sunAscendantPoints : moonAscendantPoints
                let planetName = planet.planet == .sun ? "Güneş" : "Ay"

                return ScoreBreakdown(
                    rule: planet.planet == .sun ? "sun_ascendant" : "moon_ascendant",
                    description: "\(planetName)–Yükselen \(aspectType.turkishName)",
                    points: points,
                    details: "\(String(format: "%.1f", orb))° orb"
                )
            }
        }

        return nil
    }

    // MARK: - Skor Aciklamasi

    private static func scoreDescription(for score: Int) -> ScoreDescription {
        switch score {
        case ..<5: .minimal
        case 5..<10: .medium
        case 10..<15: .important
        case 15..<20: .veryImportant
        case 20..<30: .exceptional
        default: .rareExceptional
        }
    }
}

// AspectType.turkishName ve .symbol TransitAspect.swift'te tanimli
