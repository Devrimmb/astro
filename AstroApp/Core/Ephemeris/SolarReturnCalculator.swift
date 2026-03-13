import Foundation
import SwissEphemeris

/// Solar Return (Gunes Donusu) ve Lunar Return (Ay Donusu) hesaplayici
struct SolarReturnCalculator: Sendable {

    /// Belirli bir yil icin Solar Return tarihini ve haritasini hesapla
    static func calculate(
        natalChart: BirthChart,
        year: Int,
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone
    ) async -> SolarReturn {
        JPLFileManager.setEphemerisPath()

        // Natal Gunes boylamini bul
        guard let natalSun = natalChart.planets.first(where: { $0.planet == .sun }) else {
            // Fallback: dogum tarihinde hesapla
            let calculator = SwissEphemerisCalculator()
            let chart = await calculator.calculateBirthChart(
                date: natalChart.birthDate, latitude: latitude, longitude: longitude, timeZone: timeZone
            )
            return SolarReturn(year: year, exactDate: natalChart.birthDate, chart: chart)
        }

        let targetLongitude = natalSun.longitude

        // Hedef yilin dogum gunu civari arama baslangici (10 gun once)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let birthComponents = calendar.dateComponents([.month, .day], from: natalChart.birthDate)

        var searchComponents = DateComponents()
        searchComponents.year = year
        searchComponents.month = birthComponents.month
        searchComponents.day = (birthComponents.day ?? 1) - 10

        guard let searchStart = calendar.date(from: searchComponents) else {
            let chart = await SwissEphemerisCalculator().calculateBirthChart(
                date: natalChart.birthDate, latitude: latitude, longitude: longitude, timeZone: timeZone
            )
            return SolarReturn(year: year, exactDate: natalChart.birthDate, chart: chart)
        }

        // Binary search ile tam tarihi bul (1 dakika hassasiyetle)
        let exactDate = findExactReturn(
            targetLongitude: targetLongitude,
            searchStart: searchStart,
            searchDays: 25,
            body: .sun
        )

        // Solar return haritasini hesapla
        let calculator = SwissEphemerisCalculator()
        let chart = await calculator.calculateBirthChart(
            date: exactDate, latitude: latitude, longitude: longitude, timeZone: timeZone
        )

        return SolarReturn(year: year, exactDate: exactDate, chart: chart)
    }

    /// Bir sonraki Lunar Return tarihini ve haritasini hesapla
    static func calculateLunarReturn(
        natalChart: BirthChart,
        fromDate: Date,
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone
    ) async -> LunarReturn {
        JPLFileManager.setEphemerisPath()

        guard let natalMoon = natalChart.planets.first(where: { $0.planet == .moon }) else {
            let calculator = SwissEphemerisCalculator()
            let chart = await calculator.calculateBirthChart(
                date: fromDate, latitude: latitude, longitude: longitude, timeZone: timeZone
            )
            return LunarReturn(exactDate: fromDate, chart: chart)
        }

        let targetLongitude = natalMoon.longitude

        // Ay ~27.3 gunde dolanir, 30 gun icerisinde ara
        let exactDate = findExactReturn(
            targetLongitude: targetLongitude,
            searchStart: fromDate,
            searchDays: 30,
            body: .moon
        )

        let calculator = SwissEphemerisCalculator()
        let chart = await calculator.calculateBirthChart(
            date: exactDate, latitude: latitude, longitude: longitude, timeZone: timeZone
        )

        return LunarReturn(exactDate: exactDate, chart: chart)
    }

    /// Binary search ile gezegen donusu tarihini bul
    private static func findExactReturn(
        targetLongitude: Double,
        searchStart: Date,
        searchDays: Int,
        body: SwissEphemeris.Planet
    ) -> Date {
        let stepMinutes = 60.0 // 1 saat adim
        let totalSteps = Int(Double(searchDays) * 24)

        // Kaba arama — hangi saat araliginda hedef boylamdan geciyor?
        var bestDate = searchStart
        var bestDiff = 360.0

        for step in 0..<totalSteps {
            let date = searchStart.addingTimeInterval(Double(step) * stepMinutes * 60)
            let coord = Coordinate<SwissEphemeris.Planet>(body: body, date: date)
            let diff = angleDifference(coord.longitude, targetLongitude)

            if abs(diff) < abs(bestDiff) {
                bestDiff = diff
                bestDate = date
            }
        }

        // Ince arama — 1 dakika hassasiyet
        var low = bestDate.addingTimeInterval(-3600)
        var high = bestDate.addingTimeInterval(3600)

        for _ in 0..<20 {
            let mid = Date(timeIntervalSince1970: (low.timeIntervalSince1970 + high.timeIntervalSince1970) / 2)
            let coord = Coordinate<SwissEphemeris.Planet>(body: body, date: mid)
            let diff = angleDifference(coord.longitude, targetLongitude)

            if abs(diff) < 0.01 {
                return mid
            }

            // Yonu belirle
            let lowCoord = Coordinate<SwissEphemeris.Planet>(body: body, date: low)
            let lowDiff = angleDifference(lowCoord.longitude, targetLongitude)

            if lowDiff * diff < 0 {
                high = mid
            } else {
                low = mid
            }
        }

        return bestDate
    }

    /// Iki aci arasindaki en kisa yol farki (-180 ile +180 arasi)
    private static func angleDifference(_ a: Double, _ b: Double) -> Double {
        var diff = a - b
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }
}
