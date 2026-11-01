import Foundation
import SwissEphemeris

/// Hayat döngüsü türü: bir dış gezegenin kendi doğum konumuna yaptığı açı
/// (ör. Satürn dönüşü = transit Satürn natal Satürn'e kavuşur).
enum LifeCycleKind: String, CaseIterable, Codable, Sendable {
    case jupiterReturn = "jupiter_return"
    case saturnSquareWaxing = "saturn_square_waxing"
    case saturnOpposition = "saturn_opposition"
    case saturnSquareWaning = "saturn_square_waning"
    case saturnReturn = "saturn_return"
    case uranusSquareWaxing = "uranus_square_waxing"
    case uranusOpposition = "uranus_opposition"
    case uranusSquareWaning = "uranus_square_waning"
    case uranusReturn = "uranus_return"
    case neptuneSquareWaxing = "neptune_square_waxing"
    case plutoSquareWaxing = "pluto_square_waxing"
    case chironReturn = "chiron_return"
    case nodeReturn = "node_return"

    var planet: Planet {
        switch self {
        case .jupiterReturn: .jupiter
        case .saturnSquareWaxing, .saturnOpposition, .saturnSquareWaning, .saturnReturn: .saturn
        case .uranusSquareWaxing, .uranusOpposition, .uranusSquareWaning, .uranusReturn: .uranus
        case .neptuneSquareWaxing: .neptune
        case .plutoSquareWaxing: .pluto
        case .chironReturn: .chiron
        case .nodeReturn: .northNode
        }
    }

    /// Transit gezegenin natal konumdan zodyak yönünde ne kadar ileride olduğu
    var offset: Double {
        switch self {
        case .jupiterReturn, .saturnReturn, .uranusReturn, .chironReturn, .nodeReturn: 0
        case .saturnSquareWaxing, .uranusSquareWaxing, .neptuneSquareWaxing, .plutoSquareWaxing: 90
        case .saturnOpposition, .uranusOpposition: 180
        case .saturnSquareWaning, .uranusSquareWaning: 270
        }
    }

    /// Aynı türün art arda gelen olaylarını numaralandırmak anlamlı mı (1. Jüpiter dönüşü, 2. …)
    var isRecurring: Bool {
        switch self {
        case .jupiterReturn, .saturnSquareWaxing, .saturnOpposition, .saturnSquareWaning,
             .saturnReturn, .nodeReturn: true
        default: false
        }
    }
}

/// Hesaplanmış tek bir hayat döngüsü dönemi
struct LifeCycleEvent: Identifiable, Sendable {
    var id: String { "\(kind.rawValue)_\(occurrence)" }
    let kind: LifeCycleKind
    /// Aynı türün kaçıncı gerçekleşmesi (1'den başlar)
    let occurrence: Int
    /// Tam açı anları; retro hareket nedeniyle 1–3 (düğümde daha fazla) olabilir
    let hits: [Date]

    var start: Date { hits.first! }
    var end: Date { hits.last! }
}

/// Doğum haritasından hayat döngülerini hesaplar. Ağır iş: arka planda çağır.
enum LifeCycleCalculator {
    /// Doğumdan itibaren taranan süre
    static let lifespanYears = 90

    /// - Parameters:
    ///   - natalChart: Kişinin doğum haritası (natal boylamlar buradan alınır)
    ///   - birthInstant: Doğum anı (UTC), `EphemerisManager.birthInstant` ile düzeltilmiş
    static func calculate(natalChart: BirthChart, birthInstant: Date) -> [LifeCycleEvent] {
        JPLFileManager.setEphemerisPath()
        let calendar = Calendar(identifier: .gregorian)
        // İlk yıl atlanır: dönüşlerde başlangıç anı zaten "tam açı"dır
        guard let from = calendar.date(byAdding: .year, value: 1, to: birthInstant),
              let to = calendar.date(byAdding: .year, value: lifespanYears, to: birthInstant) else { return [] }

        var events: [LifeCycleEvent] = []
        let byPlanet = Dictionary(grouping: LifeCycleKind.allCases, by: \.planet)

        for (planet, kinds) in byPlanet {
            guard let natal = natalChart.planets.first(where: { $0.planet == planet })?.longitude,
                  let longitude = longitudeFunction(for: planet) else { continue }

            let hitsByKind = crossings(
                longitude: longitude,
                targets: kinds.map { (kind: $0, target: norm(natal + $0.offset)) },
                from: from, to: to,
                stepDays: stepDays(for: planet)
            )

            for kind in kinds {
                for (index, group) in groupHits(hitsByKind[kind] ?? []).enumerated() {
                    events.append(LifeCycleEvent(kind: kind, occurrence: index + 1, hits: group))
                }
            }
        }
        return events.sorted { $0.start < $1.start }
    }

    // MARK: - Tarama

    /// Gezegen boylamını günlük adımlarla tarar; her hedefin geçildiği anı ikiye bölerek daraltır.
    private static func crossings(
        longitude: (Date) -> Double,
        targets: [(kind: LifeCycleKind, target: Double)],
        from: Date, to: Date, stepDays: Double
    ) -> [LifeCycleKind: [Date]] {
        let step = stepDays * 86_400
        var result: [LifeCycleKind: [Date]] = [:]
        var t0 = from
        var lon0 = longitude(t0)

        while t0 < to {
            let t1 = t0.addingTimeInterval(step)
            let lon1 = longitude(t1)
            for (kind, target) in targets {
                let d0 = signedDiff(lon0, target)
                let d1 = signedDiff(lon1, target)
                // İşaret değişimi + küçük fark: hedef geçildi (±180 sıçraması değil)
                if d0 == 0 || (d0 < 0) != (d1 < 0), abs(d0) < 20, abs(d1) < 20 {
                    result[kind, default: []].append(
                        refine(longitude: longitude, target: target, low: t0, high: t1))
                }
            }
            t0 = t1
            lon0 = lon1
        }
        return result
    }

    /// Hedef boylamın geçildiği anı ~1 dakika hassasiyetle bulur
    private static func refine(longitude: (Date) -> Double, target: Double, low: Date, high: Date) -> Date {
        var low = low, high = high
        let lowSign = signedDiff(longitude(low), target) < 0
        for _ in 0..<14 {
            let mid = Date(timeIntervalSince1970: (low.timeIntervalSince1970 + high.timeIntervalSince1970) / 2)
            if (signedDiff(longitude(mid), target) < 0) == lowSign { low = mid } else { high = mid }
        }
        return low
    }

    /// Birbirine 2 yıldan yakın geçişler (retro dönüşleri) tek dönemdir
    private static func groupHits(_ hits: [Date]) -> [[Date]] {
        var groups: [[Date]] = []
        for hit in hits.sorted() {
            if let last = groups.last?.last, hit.timeIntervalSince(last) < 2 * 365.25 * 86_400 {
                groups[groups.count - 1].append(hit)
            } else {
                groups.append([hit])
            }
        }
        return groups
    }

    // MARK: - Gezegenler

    private static func longitudeFunction(for planet: Planet) -> ((Date) -> Double)? {
        switch planet {
        case .jupiter: { Coordinate<SwissEphemeris.Planet>(body: .jupiter, date: $0).longitude }
        case .saturn: { Coordinate<SwissEphemeris.Planet>(body: .saturn, date: $0).longitude }
        case .uranus: { Coordinate<SwissEphemeris.Planet>(body: .uranus, date: $0).longitude }
        case .neptune: { Coordinate<SwissEphemeris.Planet>(body: .neptune, date: $0).longitude }
        case .pluto: { Coordinate<SwissEphemeris.Planet>(body: .pluto, date: $0).longitude }
        case .chiron: { Coordinate<Asteroid>(body: .chiron, date: $0).longitude }
        case .northNode: { Coordinate<LunarNorthNode>(body: .trueNode, date: $0).longitude }
        default: nil
        }
    }

    /// Adım boyu gezegenin en yüksek günlük hızının çok altında kalmalı (hedef atlanmasın)
    private static func stepDays(for planet: Planet) -> Double {
        switch planet {
        case .jupiter, .northNode: 1
        case .saturn, .chiron: 2
        default: 4
        }
    }

    private static func norm(_ x: Double) -> Double {
        let r = x.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    /// a − b, (-180, 180] aralığında
    private static func signedDiff(_ a: Double, _ b: Double) -> Double {
        var d = (a - b).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d <= -180 { d += 360 }
        return d
    }
}
