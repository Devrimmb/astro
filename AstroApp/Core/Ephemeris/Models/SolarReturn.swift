import Foundation

/// Solar Return (Gunes Donusu) haritasi
struct SolarReturn: Sendable {
    let year: Int
    let exactDate: Date
    let chart: BirthChart

    /// Solar return ASC burcu — yilin genel tonunu belirler
    var returnAscendant: ZodiacSign? {
        chart.ascendant
    }

    /// Solar return Ay burcu — yilin duygusal temasi
    var returnMoonSign: ZodiacSign? {
        chart.moonSign
    }

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy HH:mm"
        return formatter.string(from: exactDate)
    }
}

/// Lunar Return (Ay Donusu) haritasi
struct LunarReturn: Sendable {
    let exactDate: Date
    let chart: BirthChart

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy HH:mm"
        return formatter.string(from: exactDate)
    }
}
