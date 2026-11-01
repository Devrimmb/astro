import Foundation

@Observable
final class EphemerisManager {
    private let calculator: any EphemerisCalculating

    init(calculator: any EphemerisCalculating = SwissEphemerisCalculator()) {
        self.calculator = calculator
    }

    // MARK: - Natal Chart

    /// `date`: DatePicker'dan gelen, cihaz saat diliminde kurulmuş doğum anı.
    /// `timeZone`: doğum yerinin saat dilimi — girilen saat bu yerin yerel saati kabul edilir.
    func calculateBirthChart(
        date: Date, latitude: Double, longitude: Double, timeZone: TimeZone
    ) async -> BirthChart {
        let instant = Self.birthInstant(from: date, in: timeZone)
        let chart = await calculator.calculateBirthChart(
            date: instant, latitude: latitude, longitude: longitude, timeZone: timeZone
        )
        // Gösterimde kullanıcının girdiği tarih/saat korunur
        return BirthChart(
            birthDate: date,
            latitude: chart.latitude,
            longitude: chart.longitude,
            timeZoneIdentifier: chart.timeZoneIdentifier,
            planets: chart.planets,
            houses: chart.houses,
            aspects: chart.aspects
        )
    }

    /// Duvar saatini (yıl/ay/gün/saat/dakika) cihaz saat diliminden okuyup doğum yerinin
    /// saat diliminde yeniden kurar. Tarihsel yaz saati kuralları TimeZone verisinden gelir.
    static func birthInstant(
        from date: Date, in birthTimeZone: TimeZone, deviceTimeZone: TimeZone = .current
    ) -> Date {
        guard birthTimeZone.identifier != deviceTimeZone.identifier else { return date }
        var source = Calendar(identifier: .gregorian)
        source.timeZone = deviceTimeZone
        var target = Calendar(identifier: .gregorian)
        target.timeZone = birthTimeZone
        let comps = source.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return target.date(from: comps) ?? date
    }

    // MARK: - Transit

    func calculateTransits(for natalChart: BirthChart, date: Date = .now) -> TransitReport {
        TransitCalculator.calculate(natalChart: natalChart, transitDate: date)
    }

    /// Guncel gezegen pozisyonlari
    func currentPlanetPositions() -> [PlanetPosition] {
        TransitCalculator.calculatePositions(for: .now)
    }

    // MARK: - Solar Return

    func calculateSolarReturn(
        natalChart: BirthChart, year: Int, latitude: Double, longitude: Double, timeZone: TimeZone
    ) async -> SolarReturn {
        await SolarReturnCalculator.calculate(
            natalChart: natalChart, year: year,
            latitude: latitude, longitude: longitude, timeZone: timeZone
        )
    }

    // MARK: - Lunar Return

    func calculateLunarReturn(
        natalChart: BirthChart, fromDate: Date = .now, latitude: Double, longitude: Double, timeZone: TimeZone
    ) async -> LunarReturn {
        await SolarReturnCalculator.calculateLunarReturn(
            natalChart: natalChart, fromDate: fromDate,
            latitude: latitude, longitude: longitude, timeZone: timeZone
        )
    }

    // MARK: - Synastry

    func calculateSynastry(chart1: BirthChart, chart2: BirthChart) -> SynastryResult {
        SynastryCalculator.calculate(chart1: chart1, chart2: chart2)
    }
}
