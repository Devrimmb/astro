import Foundation

@Observable
final class EphemerisManager {
    private let calculator: any EphemerisCalculating

    init(calculator: any EphemerisCalculating = SwissEphemerisCalculator()) {
        self.calculator = calculator
    }

    // MARK: - Natal Chart

    func calculateBirthChart(
        date: Date, latitude: Double, longitude: Double, timeZone: TimeZone
    ) async -> BirthChart {
        await calculator.calculateBirthChart(
            date: date, latitude: latitude, longitude: longitude, timeZone: timeZone
        )
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
