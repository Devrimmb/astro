import SwiftUI

/// Kozmik kimlik hikâyesinin verisi: tamamı kişinin doğum haritasından türetilir.
struct CosmicIdentity {
    let name: String
    let chart: BirthChart
    var cityName: String?
    /// Hayat Döngüleri'nden; hesaplanınca dolar
    var nextCycle: (event: LifeCycleEvent, isActive: Bool)?

    var pages: [CosmicIdentityPage] {
        var list: [CosmicIdentityPage] = [.cover, .bigThree, .element, .signature]
        if nextCycle != nil { list.append(.cycle) }
        return list
    }

    var birthLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy"
        let date = f.string(from: chart.birthDate)
        if let cityName, !cityName.isEmpty { return "\(date) · \(cityName)" }
        return date
    }

    /// Element yüzdeleri (Büyük Üçlü ağırlıklı puanlardan), büyükten küçüğe
    var elementPercents: [(element: ZodiacSign.Element, percent: Int)] {
        let balance = chart.elementBalance
        let total = balance.values.reduce(0, +)
        guard total > 0 else { return [] }
        var list: [(element: ZodiacSign.Element, percent: Int)] = []
        for element in ZodiacSign.Element.allCases {
            let share: Double = balance[element, default: 0] / total * 100
            list.append((element, Int(share.rounded())))
        }
        return list.sorted { $0.percent > $1.percent }
    }

    /// Önem ağırlığı en yüksek majör açı
    var strongestAspect: Aspect? {
        chart.aspects
            .filter { $0.type.isMajor }
            .max { ChartSynthesizer.weight($0) < ChartSynthesizer.weight($1) }
    }
}

enum CosmicIdentityPage: Int, CaseIterable, Identifiable {
    case cover, bigThree, element, signature, cycle
    var id: Int { rawValue }
}

/// Klasik burç nitelemeleri (kanonik, kısa) ve modalite cümleleri
enum CosmicIdentityText {
    static func keywords(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: "cesur · öncü · ateşli"
        case .taurus: "sabırlı · güvenilir · duyusal"
        case .gemini: "meraklı · çok yönlü · iletişimci"
        case .cancer: "şefkatli · koruyucu · sezgisel"
        case .leo: "cömert · yaratıcı · ışıltılı"
        case .virgo: "analitik · titiz · yardımsever"
        case .libra: "uyumlu · zarif · adil"
        case .scorpio: "tutkulu · derin · dönüştürücü"
        case .sagittarius: "özgür · iyimser · maceracı"
        case .capricorn: "disiplinli · hırslı · kararlı"
        case .aquarius: "özgün · yenilikçi · bağımsız"
        case .pisces: "hayalperest · empatik · sezgisel"
        }
    }

    static func modalityTitle(_ modality: ZodiacSign.Modality) -> String {
        "\(modality.displayName) ruh"
    }

    static func modalityLine(_ modality: ZodiacSign.Modality) -> String {
        switch modality {
        case .cardinal: "Başlatan, harekete geçiren bir enerji; yeni şeylere ilk adımı atmaya eğilimlisin."
        case .fixed: "Sürdüren, derinleştiren bir enerji; başladığını kalıcı kılmaya eğilimlisin."
        case .mutable: "Uyum sağlayan, esnek bir enerji; değişime kolayca ayak uydurmaya eğilimlisin."
        }
    }

    static func elementIcon(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire: "flame.fill"
        case .earth: "leaf.fill"
        case .air: "wind"
        case .water: "drop.fill"
        }
    }
}
