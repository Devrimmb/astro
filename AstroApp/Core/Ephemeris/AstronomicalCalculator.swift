import Foundation

struct AstronomicalCalculator: EphemerisCalculating, Sendable {

    func calculateBirthChart(
        date: Date, latitude: Double, longitude: Double, timeZone: TimeZone
    ) async -> BirthChart {
        let jd = julianDay(from: date)
        let T = (jd - 2451545.0) / 36525.0 // Julian centuries from J2000.0

        let sunLon = sunLongitude(T: T)
        let moonLon = moonLongitude(T: T)
        let mercuryLon = mercuryLongitude(T: T)
        let venusLon = venusLongitude(T: T)
        let marsLon = marsLongitude(T: T)
        let jupiterLon = jupiterLongitude(T: T)
        let saturnLon = saturnLongitude(T: T)
        let uranusLon = uranusLongitude(T: T)
        let neptuneLon = neptuneLongitude(T: T)
        let plutoLon = plutoLongitude(T: T)
        let nodeLon = northNodeLongitude(T: T)
        let chironLon = chironLongitude(T: T)

        let ascLon = ascendant(jd: jd, latitude: latitude, longitude: longitude)
        let houses = generateHouses(ascendant: ascLon)

        let longitudes: [(Planet, Double)] = [
            (.sun, sunLon), (.moon, moonLon), (.mercury, mercuryLon),
            (.venus, venusLon), (.mars, marsLon), (.jupiter, jupiterLon),
            (.saturn, saturnLon), (.uranus, uranusLon), (.neptune, neptuneLon),
            (.pluto, plutoLon), (.northNode, nodeLon), (.chiron, chironLon)
        ]

        let speeds: [Planet: Double] = [
            .sun: 0.9856, .moon: 13.176, .mercury: 1.383,
            .venus: 1.2, .mars: 0.524, .jupiter: 0.083,
            .saturn: 0.034, .uranus: 0.012, .neptune: 0.006,
            .pluto: 0.004, .northNode: -0.053, .chiron: 0.02
        ]

        var planets: [PlanetPosition] = []
        for (planet, lon) in longitudes {
            let normalizedLon = normalize(lon)
            let houseNum = houseForLongitude(normalizedLon, houses: houses)
            planets.append(PlanetPosition(
                planet: planet,
                longitude: normalizedLon,
                latitude: 0,
                speed: speeds[planet] ?? 0,
                house: houseNum
            ))
        }

        let aspects = AspectCalculator.calculate(planets: planets, houses: houses)

        return BirthChart(
            birthDate: date,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone.identifier,
            planets: planets,
            houses: houses,
            aspects: aspects
        )
    }

    // MARK: - Julian Day

    private func julianDay(from date: Date) -> Double {
        let cal = Calendar(identifier: .gregorian)
        let utcZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents(in: utcZone, from: date)

        let year = Double(comps.year ?? 2000)
        let month = Double(comps.month ?? 1)
        let day = Double(comps.day ?? 1)
        let hour = Double(comps.hour ?? 0)
        let minute = Double(comps.minute ?? 0)
        let second = Double(comps.second ?? 0)

        let dayFrac = day + (hour + minute / 60.0 + second / 3600.0) / 24.0

        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }

        let A = floor(y / 100.0)
        let B = 2 - A + floor(A / 4.0)

        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + dayFrac + B - 1524.5
    }

    private func normalize(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360.0)
        if d < 0 { d += 360.0 }
        return d
    }

    private func rad(_ deg: Double) -> Double { deg * .pi / 180.0 }
    private func deg(_ rad: Double) -> Double { rad * 180.0 / .pi }

    // MARK: - Sun (VSOP87 simplified)

    private func sunLongitude(T: Double) -> Double {
        // Geometric mean longitude
        let L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
        // Mean anomaly
        let M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
        let Mrad = rad(M)

        // Equation of center
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(Mrad)
            + (0.019993 - 0.000101 * T) * sin(2 * Mrad)
            + 0.000289 * sin(3 * Mrad)

        // Sun's true longitude
        let sunTrueLon = L0 + C

        // Apparent longitude (nutation correction)
        let omega = 125.04 - 1934.136 * T
        let apparent = sunTrueLon - 0.00569 - 0.00478 * sin(rad(omega))

        return normalize(apparent)
    }

    // MARK: - Moon (simplified Brown's lunar theory)

    private func moonLongitude(T: Double) -> Double {
        // Mean longitude
        let Lp = 218.3165 + 481267.8813 * T
        // Mean elongation
        let D = 297.8502 + 445267.1115 * T
        // Sun's mean anomaly
        let M = 357.5291 + 35999.0503 * T
        // Moon's mean anomaly
        let Mp = 134.9634 + 477198.8676 * T
        // Moon's argument of latitude
        let F = 93.2720 + 483202.0175 * T

        let Drad = rad(D)
        let Mrad = rad(M)
        let Mprad = rad(Mp)
        let Frad = rad(F)

        // Principal terms of longitude (degrees)
        var lon = Lp
        lon += 6.289 * sin(Mprad)                          // Evection
        lon += 1.274 * sin(2 * Drad - Mprad)               // Variation
        lon += 0.658 * sin(2 * Drad)                        // Variation
        lon += 0.214 * sin(2 * Mprad)                       // Evection
        lon -= 0.186 * sin(Mrad)                            // Equation of year
        lon -= 0.114 * sin(2 * Frad)                        // Reduction to ecliptic
        lon += 0.059 * sin(2 * Drad - 2 * Mprad)
        lon += 0.057 * sin(2 * Drad - Mrad - Mprad)
        lon += 0.053 * sin(2 * Drad + Mprad)
        lon += 0.046 * sin(2 * Drad - Mrad)
        lon -= 0.041 * sin(Mrad - Mprad)
        lon -= 0.035 * sin(Drad)                            // Parallactic equation
        lon -= 0.030 * sin(Mrad + Mprad)

        return normalize(lon)
    }

    // MARK: - Mercury

    private func mercuryLongitude(T: Double) -> Double {
        let L = 252.2509 + 149474.0722 * T
        let M = 174.7948 + 149472.5153 * T
        let Mrad = rad(M)

        var lon = L
        lon += 23.440 * sin(Mrad)
        lon += 2.9818 * sin(2 * Mrad)
        lon += 0.5255 * sin(3 * Mrad)
        lon += 0.1058 * sin(4 * Mrad)

        // Perturbation from Venus and Jupiter
        let Mv = 50.4161 + 58519.2131 * T
        let Mj = 20.0202 + 3034.6961 * T
        lon += 0.3862 * sin(rad(2 * Mv - 5 * M + 186.0))
        lon += 0.0447 * sin(rad(Mj - M))

        return normalize(lon)
    }

    // MARK: - Venus

    private func venusLongitude(T: Double) -> Double {
        let L = 181.9798 + 58519.2131 * T
        let M = 50.4161 + 58517.8039 * T
        let Mrad = rad(M)

        var lon = L
        lon += 0.7758 * sin(Mrad)
        lon += 0.0033 * sin(2 * Mrad)

        // Earth perturbation
        let Me = 357.5291 + 35999.0503 * T
        lon += 0.0047 * sin(rad(Me - M))

        return normalize(lon)
    }

    // MARK: - Mars

    private func marsLongitude(T: Double) -> Double {
        let L = 355.4330 + 19141.6964 * T
        let M = 19.3730 + 19139.8585 * T
        let Mrad = rad(M)

        var lon = L
        lon += 10.6912 * sin(Mrad)
        lon += 0.6228 * sin(2 * Mrad)
        lon += 0.0503 * sin(3 * Mrad)
        lon += 0.0046 * sin(4 * Mrad)

        // Jupiter perturbation
        let Mj = 20.0202 + 3034.6961 * T
        lon += 0.0813 * sin(rad(2 * Mj - M + 50.0))

        return normalize(lon)
    }

    // MARK: - Jupiter

    private func jupiterLongitude(T: Double) -> Double {
        let L = 34.3515 + 3034.9057 * T
        let M = 20.0202 + 3034.6961 * T
        let Mrad = rad(M)

        var lon = L
        lon += 5.5549 * sin(Mrad)
        lon += 0.1683 * sin(2 * Mrad)
        lon += 0.0072 * sin(3 * Mrad)

        // Saturn perturbation
        let Ms = 317.0207 + 1222.1138 * T
        lon += 0.1027 * sin(rad(2 * M - 5 * Ms + 58.0))

        return normalize(lon)
    }

    // MARK: - Saturn

    private func saturnLongitude(T: Double) -> Double {
        let L = 50.0774 + 1223.5110 * T
        let M = 317.0207 + 1222.1138 * T
        let Mrad = rad(M)

        var lon = L
        lon += 6.3585 * sin(Mrad)
        lon += 0.2204 * sin(2 * Mrad)
        lon += 0.0106 * sin(3 * Mrad)

        // Jupiter perturbation
        let Mj = 20.0202 + 3034.6961 * T
        lon -= 0.1103 * sin(rad(2 * Mj - 5 * M + 58.0))

        return normalize(lon)
    }

    // MARK: - Uranus

    private func uranusLongitude(T: Double) -> Double {
        let L = 314.0550 + 429.8640 * T
        let M = 141.0500 + 429.8631 * T
        let Mrad = rad(M)

        var lon = L
        lon += 5.3117 * sin(Mrad)
        lon += 0.1395 * sin(2 * Mrad)

        return normalize(lon)
    }

    // MARK: - Neptune

    private func neptuneLongitude(T: Double) -> Double {
        let L = 304.3487 + 219.8833 * T
        let M = 256.2250 + 219.8833 * T
        let Mrad = rad(M)

        var lon = L
        lon += 1.0302 * sin(Mrad)
        lon += 0.0058 * sin(2 * Mrad)

        return normalize(lon)
    }

    // MARK: - Pluto (simplified)

    private func plutoLongitude(T: Double) -> Double {
        // Pluto's highly elliptical orbit needs special treatment
        // Using polynomial fit valid ~1900-2100
        let J = 2451545.0 + T * 36525.0
        let t = (J - 2451545.0) / 36525.0

        var lon = 238.958116 + 144.9600 * t
        let S = rad(50.03 + 0.0330 * t * 36525.0)
        let P = rad(238.95 + 0.003968 * t * 36525.0)

        lon += 6.7 * sin(S)
        lon += 6.3 * sin(P)
        lon -= 1.2 * sin(S - P)

        return normalize(lon)
    }

    // MARK: - North Node (mean)

    private func northNodeLongitude(T: Double) -> Double {
        let lon = 125.0446 - 1934.1363 * T + 0.0021 * T * T
        return normalize(lon)
    }

    // MARK: - Chiron (simplified)

    private func chironLongitude(T: Double) -> Double {
        // Chiron orbital period ~50.7 years
        // Epoch J2000.0: Chiron at ~276° (Sagittarius)
        let M = 210.0 + 7.0997 * T * 36525.0 / 360.0 * 7.104
        let Mrad = rad(M)

        var lon = 209.0 + 7.1 * T * 36525.0 / 50.7 * (360.0 / 365.25) * 50.7 / 360.0
        lon = 276.0 + (T * 36525.0) * (360.0 / (50.7 * 365.25))
        lon += 8.0 * sin(Mrad)

        return normalize(lon)
    }

    // MARK: - Ascendant

    private func ascendant(jd: Double, latitude: Double, longitude: Double) -> Double {
        let T = (jd - 2451545.0) / 36525.0

        // Greenwich Mean Sidereal Time (degrees)
        let jd0 = floor(jd - 0.5) + 0.5
        let daysSinceJ2000 = jd0 - 2451545.0
        let centuriesSinceJ2000 = daysSinceJ2000 / 36525.0
        let gmst0h = 100.46061837 + 36000.770053608 * centuriesSinceJ2000
            + 0.000387933 * centuriesSinceJ2000 * centuriesSinceJ2000

        // Hours since midnight UT
        let ut = (jd - jd0) * 24.0
        let gmst = gmst0h + ut * 1.00273790935 * 15.0

        // Local Sidereal Time
        let lst = normalize(gmst + longitude)

        // Obliquity of ecliptic
        let eps = 23.4393 - 0.013 * T
        let epsRad = rad(eps)

        let lstRad = rad(lst)
        let latRad = rad(latitude)

        // Ascendant formula
        let y = -cos(lstRad)
        let x = sin(epsRad) * tan(latRad) + cos(epsRad) * sin(lstRad)

        var asc = deg(atan2(y, x))
        asc = normalize(asc)

        return asc
    }

    // MARK: - Houses (Equal house system)

    private func generateHouses(ascendant: Double) -> [House] {
        (1...12).map { number in
            let cusp = normalize(ascendant + Double(number - 1) * 30.0)
            return House(id: number, cusp: cusp, planets: [])
        }
    }

    private func houseForLongitude(_ longitude: Double, houses: [House]) -> Int {
        for i in 0..<houses.count {
            let current = houses[i].cusp
            let next = i + 1 < houses.count ? houses[i + 1].cusp : houses[0].cusp + 360
            var adjustedNext = next
            if adjustedNext < current { adjustedNext += 360 }
            var adjustedLon = longitude
            if adjustedLon < current { adjustedLon += 360 }
            if adjustedLon >= current && adjustedLon < adjustedNext {
                return houses[i].id
            }
        }
        return 1
    }
}
