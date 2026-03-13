import Foundation
import SwissEphemeris

/// Mean Lilith (Kara Ay) — IPL body number 12 (SE_MEAN_APOG)
/// SwissEphemeris kutuphanesinde dogrudan desteklenmiyor, bu yuzden kendi tipimizi olusturuyoruz.
enum LunarApogee: Int32, CaseIterable, Codable {
    /// Mean Black Moon Lilith (Mean Lunar Apogee)
    case mean = 12
    /// Osculating (True) Black Moon Lilith
    case osculating = 13
}

extension LunarApogee: CelestialBody {
    var value: Int32 { rawValue }
}
