import Foundation

/// Sabit yildiz pozisyonlarini hesaplar (J2000.0 epoch + precession)
/// SwissEphemeris FixedStar API'si strdup crash verdiginden, onceden hesaplanmis pozisyonlar kullanilir.
struct FixedStarCalculator: Sendable {

    /// J2000.0 epoch (1 Ocak 2000 12:00 UTC) sabit yildiz pozisyonlari
    /// Kaynaklar: Stellarium, astro.com fixed stars database
    private static let starData: [(String, String, Double, Double, Double, String)] = [
        // (name, turkishName, J2000 longitude, latitude, magnitude, nature)
        ("Regulus",        "Kral Yıldızı",       149.83, 0.46,   1.4,  "Mars/Jüpiter — başarı, liderlik, soyluluk"),
        ("Algol",          "Şeytan Yıldızı",     56.17,  22.41,  2.1,  "Satürn/Jüpiter — zorluk, dönüşüm, güç"),
        ("Sirius",         "Köpek Yıldızı",      104.07, -39.61, -1.5, "Jüpiter/Mars — parlaklık, şans, ünlü olma"),
        ("Spica",          "Başak Yıldızı",      203.84, -2.05,  1.0,  "Venüs/Mars — yetenek, başarı, şans"),
        ("Aldebaran",      "Boğa'nın Gözü",      69.87,  -5.47,  0.9,  "Mars — cesaret, liderlik, tutku"),
        ("Antares",        "Akrep'in Kalbi",     249.29, -4.57,  1.1,  "Mars/Jüpiter — yıkılmaz irade, tutku"),
        ("Rigel",          "Orion'un Ayağı",     78.63,  -31.07, 0.1,  "Jüpiter/Satürn — bilim, öğretmenlik, başarı"),
        ("Altair",         "Uçan Kartal",        301.87, 29.31,  0.8,  "Mars/Jüpiter — cesaret, risk alma, hareket"),
        ("Arcturus",       "Ayı Koruyucu",       214.00, 30.75,  0.0,  "Mars/Jüpiter — yenilikçilik, buluş"),
        ("Procyon",        "Küçük Köpek",        115.32, -16.01, 0.4,  "Merkür/Mars — hızlı düşünce, telaşçılık"),
        ("Betelgeuse",     "Orion'un Omuzu",     88.79,  -16.03, 0.4,  "Mars/Merkür — savaş onuru, strateji"),
        ("Capella",        "Küçük Keçi",         81.28,  22.93,  0.1,  "Jüpiter/Satürn — merak, öğrenme, sevgi"),
        ("Castor",         "İkizlerin Biri",     113.65, 10.09,  1.6,  "Merkür — yazarlık, iletişim, zeka"),
        ("Pollux",         "İkizlerin Diğeri",   116.33, 6.68,   1.2,  "Mars — cesaret, dayanıklılık, atılganlık"),
        ("Galaktik Merkez","Samanyolu Kalbi",     266.42, -5.60,  0.0,  "Jüpiter/Satürn — ruhani bilgi, vizyon"),
    ]

    /// Yillik precession orani (derece/yil) — yaklasik 50.3 arcsaniye
    private static let precessionRate = 50.3 / 3600.0

    /// J2000.0 epoch referans tarihi
    private static let j2000: Date = {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }()

    /// Belirli bir tarih icin tum sabit yildiz pozisyonlarini hesapla
    static func calculatePositions(date: Date) -> [FixedStarPosition] {
        let yearsSinceJ2000 = date.timeIntervalSince(j2000) / (365.25 * 86400)
        let precessionOffset = yearsSinceJ2000 * precessionRate

        return starData.map { name, turkishName, j2000Lon, latitude, magnitude, nature in
            let currentLon = (j2000Lon + precessionOffset).truncatingRemainder(dividingBy: 360)
            let adjustedLon = currentLon < 0 ? currentLon + 360 : currentLon

            return FixedStarPosition(
                name: name,
                turkishName: turkishName,
                longitude: adjustedLon,
                latitude: latitude,
                magnitude: magnitude,
                nature: nature
            )
        }
    }

    /// Natal gezegenlerle kavusumlari bul
    static func findConjunctions(
        chart: BirthChart,
        date: Date,
        orb: Double = 1.5
    ) -> [FixedStarConjunction] {
        let stars = calculatePositions(date: date)
        var conjunctions: [FixedStarConjunction] = []

        for star in stars {
            for pos in chart.planets {
                guard Planet.classicPlanets.contains(pos.planet) || pos.planet == .northNode else { continue }
                var diff = abs(star.longitude - pos.longitude)
                if diff > 180 { diff = 360 - diff }
                if diff <= orb {
                    conjunctions.append(FixedStarConjunction(
                        star: star,
                        planet: pos.planet,
                        orb: diff
                    ))
                }
            }
        }

        return conjunctions.sorted { $0.orb < $1.orb }
    }
}
