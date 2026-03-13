import Foundation

protocol EphemerisCalculating: Sendable {
    func calculateBirthChart(
        date: Date, latitude: Double, longitude: Double, timeZone: TimeZone
    ) async -> BirthChart
}
