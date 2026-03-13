# 🌟 AstroApp — Tam Kapsamlı Geliştirme Roadmap'i

> **Platform:** iOS 17+ · **Dil:** Swift 5.9+ · **UI:** SwiftUI  
> **Mimari:** Offline-first, Backend'siz · **Araç:** Claude Code + Xcode  
> **Tahmini Süre:** 12-16 hafta (solo geliştirici)

---

## 📐 Mimari Genel Bakış

```
AstroApp/
├── App/
│   ├── AstroApp.swift                  # @main entry point
│   ├── AppState.swift                  # Global state (ObservableObject)
│   └── ContentView.swift               # Tab-based navigation
│
├── Core/
│   ├── Ephemeris/
│   │   ├── SwissEphemeris/             # C bridge (Swiss Ephemeris kütüphanesi)
│   │   ├── EphemerisManager.swift      # Gezegen pozisyonu hesaplama
│   │   ├── HouseCalculator.swift       # Ev sistemi hesaplama (Placidus)
│   │   ├── AspectCalculator.swift      # Açı hesaplama (conjunct, trine vb.)
│   │   └── Models/
│   │       ├── Planet.swift
│   │       ├── ZodiacSign.swift
│   │       ├── House.swift
│   │       └── Aspect.swift
│   │
│   ├── Interpretation/
│   │   ├── InterpretationEngine.swift  # Yorum motoru
│   │   ├── JSONLoader.swift            # Bundle'dan JSON yükleme
│   │   └── Data/                       # Gömülü JSON yorum dosyaları
│   │       ├── planets_in_signs.json
│   │       ├── planets_in_houses.json
│   │       ├── aspects.json
│   │       ├── elements.json
│   │       ├── modalities.json
│   │       └── tarot_cards.json
│   │
│   ├── Monetization/
│   │   ├── StoreManager.swift          # StoreKit 2 (In-App Purchase)
│   │   ├── AdManager.swift             # Google AdMob (rewarded ads)
│   │   └── EntitlementManager.swift    # Erişim kontrolü
│   │
│   └── AI/
│       ├── AstroMLModel.mlmodel        # Core ML modeli
│       ├── ChatEngine.swift            # Soru-cevap motoru
│       └── SpeechManager.swift         # Speech-to-Text / Text-to-Speech
│
├── Features/
│   ├── BirthChart/                     # Yıldız haritası
│   │   ├── BirthChartView.swift
│   │   ├── ChartWheelView.swift        # Canvas ile çizim
│   │   ├── BirthChartViewModel.swift
│   │   └── Components/
│   │       ├── ZodiacWheelShape.swift
│   │       ├── PlanetGlyphView.swift
│   │       ├── HouseLineView.swift
│   │       └── AspectLineView.swift
│   │
│   ├── DailyHoroscope/                 # Günlük burç yorumu
│   │   ├── DailyView.swift
│   │   └── DailyViewModel.swift
│   │
│   ├── Tarot/                          # Tarot (ücretsiz)
│   │   ├── TarotView.swift
│   │   ├── TarotViewModel.swift
│   │   ├── CardFlipAnimation.swift
│   │   └── TarotDeckView.swift
│   │
│   ├── Compatibility/                  # Burç uyumu
│   │   ├── CompatibilityView.swift
│   │   └── CompatibilityViewModel.swift
│   │
│   ├── MoonPhase/                      # Ay evreleri
│   │   ├── MoonPhaseView.swift
│   │   └── MoonCalendarView.swift
│   │
│   ├── AstroChat/                      # AI Soru-Cevap (Faz 3)
│   │   ├── AstroChatView.swift
│   │   ├── AstroChatViewModel.swift
│   │   └── VoiceInputButton.swift
│   │
│   └── Profile/
│       ├── ProfileView.swift
│       ├── BirthDataInputView.swift
│       └── SettingsView.swift
│
├── Design/
│   ├── Theme.swift                     # Renk paleti, font sistemi
│   ├── GlassModifier.swift             # Glassmorphism efektleri
│   ├── StarfieldBackground.swift       # Animasyonlu yıldızlı arka plan
│   └── Assets.xcassets/
│       ├── ZodiacGlyphs/              # 12 burç sembolü (SVG)
│       ├── PlanetGlyphs/             # Gezegen sembolleri (SVG)
│       └── TarotCards/               # 78 tarot kartı görseli
│
├── Resources/
│   ├── sweph_18/                      # Swiss Ephemeris veri dosyaları
│   │   ├── seas_18.se1               # Asteroit verileri
│   │   ├── semo_18.se1               # Ay verileri
│   │   └── sepl_18.se1               # Gezegen verileri
│   └── Localizable.strings            # Türkçe lokalizasyon
│
└── Tests/
    ├── EphemerisTests.swift           # Hesaplama doğruluk testleri
    ├── InterpretationTests.swift
    └── StoreTests.swift
```

---

## 🔭 FAZ 0 — Proje Kurulumu ve Araştırma (Hafta 1)

### 0.1 Xcode Proje Oluşturma
```bash
# Claude Code ile proje iskeleti
mkdir AstroApp && cd AstroApp
# Xcode'da yeni SwiftUI App oluştur, iOS 17+ target
```

### 0.2 Swiss Ephemeris Entegrasyonu (KRİTİK)

Bu projenin kalbi. Gezegen pozisyonlarını hesaplamak için endüstri standardı.

**Seçenek A — Swift Package (Önerilen):**
```swift
// Package.swift veya Xcode > Add Package Dependency
// https://github.com/nicklauslitworker/SwissEphemeris
// Bu paket Swiss Ephemeris'i Swift-friendly sarmalıyor
dependencies: [
    .package(url: "https://github.com/nicklauslitworker/SwissEphemeris", from: "0.5.0")
]
```

**Seçenek B — Manuel C Bridge:**
```
1. Swiss Ephemeris C kaynak kodunu indir (https://www.astro.com/swisseph/)
2. .c ve .h dosyalarını projeye ekle
3. Bridging Header oluştur:
   #include "swephexp.h"
4. Swift wrapper yaz
```

**Seçenek A tercih edilmeli** — SwissEphemeris paketi şunları sağlar:
- Gezegen pozisyonları (Güneş, Ay, Merkür...Plüton + Node'lar)
- Ev hesaplama (Placidus, Koch, Equal, Whole Sign)
- Açı hesaplama (Conjunction, Opposition, Trine, Square, Sextile)
- Zodyak dereceleri → burç dönüşümü

```swift
// Kullanım örneği
import SwissEphemeris

// Ephemeris dosyalarının path'ini ayarla
let bundle = Bundle.main
let ephePath = bundle.path(forResource: "sepl_18", ofType: "se1")!
swe_set_ephe_path(ephePath)

// Julian Day hesapla (doğum tarihi için)
let jd = swe_julday(1990, 5, 15, 14.5, SE_GREG_CAL) // 15 Mayıs 1990, 14:30

// Güneş pozisyonu hesapla
var xx = [Double](repeating: 0, count: 6)
var serr = [CChar](repeating: 0, count: 256)
swe_calc_ut(jd, SE_SUN, SEFLG_SWIEPH, &xx, &serr)
let sunLongitude = xx[0] // Ekliptik boylam (0-360 derece)
// 54.23° → Boğa burcu (30-60° arası)
```

### 0.3 Gerekli Ephemeris Dosyaları

Swiss Ephemeris'in çalışması için veri dosyaları gerekir. Bunlar app bundle'ına gömülür:

| Dosya | Boyut | İçerik |
|-------|-------|--------|
| `sepl_18.se1` | ~500KB | Ana gezegenler (Güneş-Plüton) |
| `semo_18.se1` | ~200KB | Ay verileri |
| `seas_18.se1` | ~100KB | Asteroidler (opsiyonel) |

> **Toplam bundle boyutu:** ~800KB — çok makul.

### 0.4 Ephemeris Dosyalarını İndirme

```bash
# Swiss Ephemeris resmi sitesinden indir
# https://www.astro.com/ftp/swisseph/ephe/
# veya GitHub mirror'ından
```

---

## ⭐ FAZ 1 — Çekirdek Astroloji Motoru (Hafta 2-4)

### 1.1 Veri Modelleri

```swift
// Models/Planet.swift
enum Planet: String, CaseIterable, Codable {
    case sun = "Güneş"
    case moon = "Ay"
    case mercury = "Merkür"
    case venus = "Venüs"
    case mars = "Mars"
    case jupiter = "Jüpiter"
    case saturn = "Satürn"
    case uranus = "Uranüs"
    case neptune = "Neptün"
    case pluto = "Plüton"
    case northNode = "Kuzey Düğüm"
    case chiron = "Chiron"
    
    var sweCode: Int32 {
        switch self {
        case .sun: return SE_SUN
        case .moon: return SE_MOON
        case .mercury: return SE_MERCURY
        // ...
        }
    }
}

// Models/ZodiacSign.swift
enum ZodiacSign: Int, CaseIterable, Codable {
    case aries = 0, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces
    
    var name: String { /* Türkçe isim */ }
    var element: Element { /* Ateş, Toprak, Hava, Su */ }
    var modality: Modality { /* Öncü, Sabit, Değişken */ }
    var ruler: Planet { /* Yönetici gezegen */ }
    var glyph: String { /* ♈ ♉ ♊ ... */ }
    var degreeRange: ClosedRange<Double> { /* 0...29.99, 30...59.99 */ }
    
    static func from(longitude: Double) -> ZodiacSign {
        ZodiacSign(rawValue: Int(longitude / 30.0))!
    }
}

// Models/House.swift  
struct House: Identifiable {
    let id: Int          // 1-12
    let cusp: Double     // Derece (0-360)
    var sign: ZodiacSign // Hangi burçta
    var degree: Double   // Burç içindeki derece
    var planets: [PlanetPosition] // Bu evdeki gezegenler
}

// Models/Aspect.swift
enum AspectType: Double {
    case conjunction = 0      // Kavuşum
    case sextile = 60         // Altıgen
    case square = 90          // Kare
    case trine = 120          // Üçgen
    case opposition = 180     // Karşıt
    
    var orb: Double {  // Tolerans derecesi
        switch self {
        case .conjunction, .opposition: return 8.0
        case .trine, .square: return 7.0
        case .sextile: return 5.0
        }
    }
    
    var nature: String { // Olumlu / Zorlayıcı
        switch self {
        case .trine, .sextile: return "harmonik"
        case .square, .opposition: return "zorlayıcı"
        case .conjunction: return "nötr"
        }
    }
}

struct Aspect: Identifiable {
    let id = UUID()
    let planet1: Planet
    let planet2: Planet
    let type: AspectType
    let orb: Double       // Gerçek sapma
    let applying: Bool    // Daralan mı genişleyen mi
}

// Models/BirthChart.swift — Ana model
struct BirthChart: Codable {
    let birthDate: Date
    let latitude: Double
    let longitude: Double
    let timezone: TimeZone
    
    var planets: [PlanetPosition]   // Her gezegenin burcu ve derecesi
    var houses: [House]             // 12 ev
    var aspects: [Aspect]           // Gezegenler arası açılar
    
    var sunSign: ZodiacSign         // Burç (Güneş burcu)
    var moonSign: ZodiacSign        // Ay burcu  
    var ascendant: ZodiacSign       // Yükselen
    
    var elementBalance: [Element: Int]     // Ateş: 3, Toprak: 2...
    var modalityBalance: [Modality: Int]   // Öncü: 4, Sabit: 3...
    var dominantElement: Element
    var dominantModality: Modality
}
```

### 1.2 Hesaplama Motoru

```swift
// Core/Ephemeris/EphemerisManager.swift
class EphemerisManager {
    
    static let shared = EphemerisManager()
    
    init() {
        // Ephemeris dosyalarının path'ini ayarla
        if let path = Bundle.main.resourcePath {
            swe_set_ephe_path(path)
        }
    }
    
    /// Tam doğum haritası hesapla
    func calculateBirthChart(
        date: Date,
        latitude: Double, 
        longitude: Double,
        timezone: TimeZone
    ) -> BirthChart {
        
        let jd = julianDay(from: date, timezone: timezone)
        
        // 1. Gezegen pozisyonları
        let planets = Planet.allCases.map { planet in
            calculatePlanetPosition(planet: planet, julianDay: jd)
        }
        
        // 2. Ev hesaplama (Placidus sistemi)
        let houses = calculateHouses(
            julianDay: jd, 
            latitude: latitude, 
            longitude: longitude
        )
        
        // 3. Açı hesaplama
        let aspects = calculateAspects(planets: planets)
        
        // 4. Element ve modalite dengesi
        let elementBalance = calculateElementBalance(planets: planets)
        let modalityBalance = calculateModalityBalance(planets: planets)
        
        return BirthChart(
            birthDate: date,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            planets: planets,
            houses: houses,
            aspects: aspects,
            sunSign: planets.first { $0.planet == .sun }!.sign,
            moonSign: planets.first { $0.planet == .moon }!.sign,
            ascendant: ZodiacSign.from(longitude: houses[0].cusp),
            elementBalance: elementBalance,
            modalityBalance: modalityBalance,
            dominantElement: elementBalance.max(by: { $0.value < $1.value })!.key,
            dominantModality: modalityBalance.max(by: { $0.value < $1.value })!.key
        )
    }
    
    /// Ev hesaplama — Placidus sistemi
    private func calculateHouses(
        julianDay: Double, 
        latitude: Double, 
        longitude: Double
    ) -> [House] {
        var cusps = [Double](repeating: 0, count: 13)  // 1-indexed
        var ascmc = [Double](repeating: 0, count: 10)
        
        // 'P' = Placidus sistemi
        swe_houses(julianDay, latitude, longitude, Int32(Character("P").asciiValue!), &cusps, &ascmc)
        
        return (1...12).map { i in
            let cusp = cusps[i]
            return House(
                id: i,
                cusp: cusp,
                sign: ZodiacSign.from(longitude: cusp),
                degree: cusp.truncatingRemainder(dividingBy: 30),
                planets: []
            )
        }
    }
    
    /// Julian Day hesaplama
    private func julianDay(from date: Date, timezone: TimeZone) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(
            in: timezone, from: date
        )
        let hour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
        let utOffset = Double(timezone.secondsFromGMT(for: date)) / 3600.0
        let utHour = hour - utOffset
        
        return swe_julday(
            Int32(components.year!),
            Int32(components.month!),
            Int32(components.day!),
            utHour,
            SE_GREG_CAL
        )
    }
}
```

### 1.3 Yorum Sistemi — JSON Veritabanı

Tüm yorumlar JSON dosyası olarak app bundle'ına gömülür:

```json
// Resources/Data/planets_in_signs.json
{
  "sun": {
    "aries": {
      "title": "Güneş Koç Burcunda",
      "short": "Cesur, enerjik ve öncü ruhlu.",
      "detailed": "Güneşiniz Koç burcunda olduğunda...(uzun yorum)...",
      "strengths": ["Liderlik", "Cesaret", "Girişimcilik"],
      "challenges": ["Sabırsızlık", "Düşünmeden hareket etme"],
      "advice": "Enerjinizi yapıcı kanallara yönlendirin..."
    },
    "taurus": { ... }
  },
  "moon": {
    "aries": {
      "title": "Ay Koç Burcunda",
      "short": "Duygusal tepkileri hızlı ve tutkulu.",
      "detailed": "...",
      ...
    }
  }
}

// Resources/Data/planets_in_houses.json  
{
  "sun": {
    "1": {
      "title": "Güneş 1. Evde",
      "short": "Kimlik ve benlik ifadesi ön plandadır.",
      "detailed": "1. evde Güneş, kişinin kendini ifade etme...",
      ...
    },
    "2": { ... }
  }
}

// Resources/Data/houses_in_signs.json — SENİN YORUMLARIN BURAYA
{
  "1": {
    "aries": {
      "title": "1. Ev Koç Burcunda",
      "short": "Dış dünyaya cesur ve enerjik bir görünüm sunar.",
      "detailed": "Yükselen burcunuz Koç olduğunda...(senin yorumun)..."
    },
    "taurus": {
      "title": "1. Ev Boğa Burcunda",
      "detailed": "...(senin yorumun)..."
    }
  },
  "2": {
    "aries": { ... },
    ...
  }
}

// Resources/Data/aspects.json
{
  "sun_moon": {
    "conjunction": {
      "title": "Güneş-Ay Kavuşumu",
      "interpretation": "İç dünya ile dış ifade uyum içinde..."
    },
    "opposition": { ... },
    "trine": { ... },
    "square": { ... }
  }
}
```

```swift
// Core/Interpretation/InterpretationEngine.swift
class InterpretationEngine {
    
    private var planetsInSigns: [String: [String: Interpretation]] = [:]
    private var planetsInHouses: [String: [String: Interpretation]] = [:]
    private var housesInSigns: [String: [String: Interpretation]] = [:]
    private var aspectInterpretations: [String: [String: Interpretation]] = [:]
    
    init() {
        loadAllInterpretations()
    }
    
    private func loadAllInterpretations() {
        planetsInSigns = JSONLoader.load("planets_in_signs")
        planetsInHouses = JSONLoader.load("planets_in_houses")
        housesInSigns = JSONLoader.load("houses_in_signs")
        aspectInterpretations = JSONLoader.load("aspects")
    }
    
    /// Tam harita yorumu üret
    func interpret(chart: BirthChart) -> ChartInterpretation {
        var sections: [InterpretationSection] = []
        
        // 1. Büyük Üçlü (Güneş, Ay, Yükselen)
        sections.append(interpretBigThree(chart))
        
        // 2. Her gezegen için burç yorumu
        for position in chart.planets {
            if let interp = planetsInSigns[position.planet.rawValue]?[position.sign.rawValue] {
                sections.append(InterpretationSection(
                    title: interp.title,
                    body: interp.detailed,
                    category: .planetInSign
                ))
            }
        }
        
        // 3. Her ev için burç yorumu (SENİN YORUMLARIN)
        for house in chart.houses {
            if let interp = housesInSigns["\(house.id)"]?[house.sign.rawValue] {
                sections.append(InterpretationSection(
                    title: "Ev \(house.id): \(house.sign.name)",
                    body: interp.detailed,
                    category: .houseInSign
                ))
            }
        }
        
        // 4. Açı yorumları
        for aspect in chart.aspects {
            let key = "\(aspect.planet1.rawValue)_\(aspect.planet2.rawValue)"
            if let interp = aspectInterpretations[key]?[aspect.type.rawValue] {
                sections.append(InterpretationSection(
                    title: interp.title,
                    body: interp.interpretation,
                    category: .aspect
                ))
            }
        }
        
        // 5. Element dengesi
        sections.append(interpretElements(chart.elementBalance))
        
        // 6. Modalite dengesi
        sections.append(interpretModalities(chart.modalityBalance))
        
        return ChartInterpretation(sections: sections)
    }
}
```

---

## 🎨 FAZ 2 — UI ve Yıldız Haritası Çizimi (Hafta 5-8)

### 2.1 Yıldız Haritası Çizimi (Canvas + SwiftUI)

Bu kısım en teknik kısım. SwiftUI Canvas kullanarak natal chart wheel çizilir:

```swift
// Features/BirthChart/ChartWheelView.swift
struct ChartWheelView: View {
    let chart: BirthChart
    let size: CGFloat
    
    private var center: CGPoint { CGPoint(x: size/2, y: size/2) }
    private var outerRadius: CGFloat { size/2 - 20 }
    private var signRingInner: CGFloat { outerRadius - 40 }
    private var houseRingInner: CGFloat { signRingInner - 80 }
    private var planetRingRadius: CGFloat { (signRingInner + houseRingInner) / 2 }
    private var innerRadius: CGFloat { houseRingInner - 20 }
    
    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
            
            // 1. Dış halka - 12 burç bölmesi
            drawZodiacRing(context: &context, center: center)
            
            // 2. Burç sembolleri (♈♉♊...)
            drawZodiacGlyphs(context: &context, center: center)
            
            // 3. Ev çizgileri (12 ev)
            drawHouseLines(context: &context, center: center)
            
            // 4. Ev numaraları
            drawHouseNumbers(context: &context, center: center)
            
            // 5. Gezegen sembolleri
            drawPlanets(context: &context, center: center)
            
            // 6. Açı çizgileri (merkezdeki renkli çizgiler)
            drawAspectLines(context: &context, center: center)
        }
        .frame(width: size, height: size)
    }
    
    /// Zodyak halkası — 12 eşit bölme, element renkli
    private func drawZodiacRing(context: inout GraphicsContext, center: CGPoint) {
        let ascDegree = chart.houses[0].cusp // Yükselen derece
        
        for sign in ZodiacSign.allCases {
            let startAngle = degreesToAngle(Double(sign.rawValue) * 30.0 - ascDegree)
            let endAngle = degreesToAngle(Double(sign.rawValue + 1) * 30.0 - ascDegree)
            
            var path = Path()
            path.addArc(center: center, radius: outerRadius,
                       startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.addArc(center: center, radius: signRingInner,
                       startAngle: endAngle, endAngle: startAngle, clockwise: true)
            path.closeSubpath()
            
            // Element bazlı renklendirme
            let color: Color = switch sign.element {
                case .fire: .red.opacity(0.3)
                case .earth: .green.opacity(0.3)
                case .air: .yellow.opacity(0.3)
                case .water: .blue.opacity(0.3)
            }
            
            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(.white.opacity(0.5)), lineWidth: 0.5)
        }
    }
    
    /// Açı çizgileri — haritanın merkezindeki renkli çizgiler
    private func drawAspectLines(context: inout GraphicsContext, center: CGPoint) {
        let ascDegree = chart.houses[0].cusp
        
        for aspect in chart.aspects {
            let pos1 = chart.planets.first { $0.planet == aspect.planet1 }!
            let pos2 = chart.planets.first { $0.planet == aspect.planet2 }!
            
            let angle1 = degreesToAngle(pos1.longitude - ascDegree)
            let angle2 = degreesToAngle(pos2.longitude - ascDegree)
            
            let point1 = pointOnCircle(center: center, radius: innerRadius, angle: angle1)
            let point2 = pointOnCircle(center: center, radius: innerRadius, angle: angle2)
            
            var path = Path()
            path.move(to: point1)
            path.addLine(to: point2)
            
            let color: Color = switch aspect.type {
                case .trine: .green
                case .sextile: .blue
                case .square: .red
                case .opposition: .red.opacity(0.7)
                case .conjunction: .yellow
            }
            
            let dash: [CGFloat] = aspect.type == .sextile ? [5, 5] : []
            context.stroke(path, with: .color(color), 
                          style: StrokeStyle(lineWidth: 1, dash: dash))
        }
    }
    
    /// Derece → Canvas açısı dönüşümü
    /// Astrolojide 0° = Ascendant (sol taraf), saat yönünün tersine
    /// Canvas'ta 0° = sağ taraf (3 o'clock), saat yönünde
    private func degreesToAngle(_ degree: Double) -> Angle {
        Angle(degrees: -degree + 180) // Sol taraftan başla, ters yöne
    }
}
```

### 2.2 Ana Ekranlar

```swift
// Features/BirthChart/BirthChartView.swift
struct BirthChartView: View {
    @StateObject private var vm = BirthChartViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Yıldız Haritası Wheel
                if let chart = vm.chart {
                    ChartWheelView(chart: chart, size: 350)
                        .padding()
                    
                    // Büyük Üçlü Kartları
                    BigThreeCards(
                        sun: chart.sunSign,
                        moon: chart.moonSign,
                        ascendant: chart.ascendant
                    )
                    
                    // Element Dengesi
                    ElementBalanceView(balance: chart.elementBalance)
                    
                    // Detaylı Yorumlar (scroll)
                    ForEach(vm.interpretations) { section in
                        InterpretationCard(section: section)
                    }
                } else {
                    BirthDataInputView(onSubmit: vm.calculateChart)
                }
            }
        }
        .background(StarfieldBackground())
    }
}
```

### 2.3 Tarot Modülü (Ücretsiz)

```swift
// Features/Tarot/TarotView.swift
struct TarotView: View {
    @StateObject private var vm = TarotViewModel()
    
    var body: some View {
        VStack {
            // 3 kartlık spread: Geçmiş - Şimdi - Gelecek
            HStack(spacing: 16) {
                ForEach(vm.drawnCards) { card in
                    TarotCardView(card: card, isRevealed: card.isRevealed)
                        .onTapGesture { vm.revealCard(card) }
                        .rotation3DEffect(
                            .degrees(card.isRevealed ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .animation(.spring(duration: 0.6), value: card.isRevealed)
                }
            }
            
            if vm.allRevealed {
                // Yorum
                Text(vm.interpretation)
                    .font(.body)
                    .padding()
            }
            
            Button("Kartları Çek") {
                vm.drawCards()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// TarotViewModel — 78 kartlık deste, JSON'dan yüklenir
class TarotViewModel: ObservableObject {
    @Published var drawnCards: [TarotCard] = []
    private let deck: [TarotCard] // tarot_cards.json'dan yüklenir
    
    func drawCards() {
        drawnCards = Array(deck.shuffled().prefix(3))
            .enumerated()
            .map { TarotCard(/* ... position: geçmiş/şimdi/gelecek */) }
    }
}
```

### 2.4 Tasarım Sistemi

```swift
// Design/Theme.swift
struct AstroTheme {
    // Koyu, kozmik renk paleti
    static let background = Color(hex: "#0A0E27")        // Derin gece mavisi
    static let surface = Color(hex: "#151A3A")            // Kart arka planı
    static let accent = Color(hex: "#7B68EE")             // Mistik mor
    static let gold = Color(hex: "#FFD700")               // Altın vurgular
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    
    // Element renkleri
    static let fire = Color(hex: "#FF6B6B")
    static let earth = Color(hex: "#51CF66")
    static let air = Color(hex: "#FFE066")
    static let water = Color(hex: "#74C0FC")
}

// Glassmorphism kart efekti
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: AstroTheme.accent.opacity(0.1), radius: 10)
    }
}
```

---

## 💰 FAZ 3 — Monetizasyon (Hafta 9-10)

### 3.1 Fiyatlandırma Modeli

| Özellik | Erişim | Fiyat |
|---------|--------|-------|
| Günlük Burç Yorumu | ÜCRETSİZ | - |
| Tarot Çekimi | ÜCRETSİZ | - |
| Ay Evreleri | ÜCRETSİZ | - |
| Element Analizi | ÜCRETSİZ | - |
| Detaylı Yıldız Haritası | REKLAM | Rewarded Ad izle |
| Uyum Analizi | REKLAM | Rewarded Ad izle |
| Tam Natal Chart + Yorumlar | IN-APP PURCHASE | ₺200 (tek seferlik) |
| AI Astroloji Sohbet | IN-APP PURCHASE | ₺300 (tek seferlik) |
| Tüm Özellikler Paketi | IN-APP PURCHASE | ₺400 (tek seferlik) |

### 3.2 StoreKit 2 Entegrasyonu

```swift
// Core/Monetization/StoreManager.swift
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    // Product ID'ler (App Store Connect'te tanımlanır)
    static let natalChartID = "com.astroapp.natalchart"       // ₺200
    static let aiChatID = "com.astroapp.aichat"               // ₺300
    static let allFeaturesID = "com.astroapp.allfeatures"     // ₺400
    
    private let productIDs: Set<String> = [
        natalChartID, aiChatID, allFeaturesID
    ]
    
    init() {
        Task { await loadProducts() }
        Task { await listenForTransactions() }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Ürünler yüklenemedi: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
            return true
        case .pending:
            return false
        case .userCancelled:
            return false
        @unknown default:
            return false
        }
    }
    
    /// App başlangıcında mevcut satın almaları kontrol et
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }
    
    /// Transaction listener — arka planda satın alma durumlarını dinle
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
            }
        }
    }
}
```

### 3.3 Google AdMob — Rewarded Ads

```swift
// Core/Monetization/AdManager.swift
import GoogleMobileAds

class AdManager: NSObject, ObservableObject {
    
    @Published var isRewardedAdReady = false
    @Published var rewardEarned = false
    
    private var rewardedAd: GADRewardedAd?
    
    // Test ID — yayında gerçek ID kullan
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    func loadRewardedAd() {
        GADRewardedAd.load(
            withAdUnitID: adUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            if let ad = ad {
                self?.rewardedAd = ad
                self?.isRewardedAdReady = true
            }
        }
    }
    
    func showRewardedAd(from viewController: UIViewController) {
        guard let ad = rewardedAd else { return }
        
        ad.present(fromRootViewController: viewController) { [weak self] in
            // Kullanıcı reklamı tamamladı — ödül ver
            self?.rewardEarned = true
            self?.loadRewardedAd() // Yeni reklam yükle
        }
    }
}

// SPM veya CocoaPods ile ekle:
// .package(url: "https://github.com/nicklauslitworker/google-mobile-ads-swift", ...)
// veya Podfile: pod 'Google-Mobile-Ads-SDK'
```

### 3.4 Erişim Kontrolü

```swift
// Core/Monetization/EntitlementManager.swift
class EntitlementManager: ObservableObject {
    
    @Published var store: StoreManager
    @Published var adManager: AdManager
    
    enum FeatureAccess {
        case free
        case requiresAd
        case requiresPurchase(String) // product ID
        case locked
    }
    
    func accessLevel(for feature: AppFeature) -> FeatureAccess {
        switch feature {
        case .dailyHoroscope, .tarot, .moonPhase, .elementAnalysis:
            return .free
            
        case .detailedChart, .compatibility:
            if store.purchasedProductIDs.contains(StoreManager.allFeaturesID) ||
               store.purchasedProductIDs.contains(StoreManager.natalChartID) {
                return .free
            }
            return .requiresAd
            
        case .fullNatalChart:
            if store.purchasedProductIDs.contains(StoreManager.natalChartID) ||
               store.purchasedProductIDs.contains(StoreManager.allFeaturesID) {
                return .free
            }
            return .requiresPurchase(StoreManager.natalChartID)
            
        case .aiChat:
            if store.purchasedProductIDs.contains(StoreManager.aiChatID) ||
               store.purchasedProductIDs.contains(StoreManager.allFeaturesID) {
                return .free
            }
            return .requiresPurchase(StoreManager.aiChatID)
        }
    }
    
    /// Paywall gösteren ViewModifier
    func gatedContent<Content: View>(
        feature: AppFeature,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let access = accessLevel(for: feature)
        
        switch access {
        case .free:
            content()
        case .requiresAd:
            AdGateView(adManager: adManager, content: content)
        case .requiresPurchase(let productID):
            PurchaseGateView(store: store, productID: productID, content: content)
        case .locked:
            LockedFeatureView()
        }
    }
}
```

---

## 🤖 FAZ 4 — AI Sohbet ve Sesli Etkileşim (Hafta 11-14)

### 4.1 Strateji: On-Device AI

Backend olmadan AI sohbet için 3 yaklaşım:

| Yaklaşım | Avantaj | Dezavantaj |
|-----------|---------|------------|
| **Core ML + Kendi Modelin** | Tamamen offline, hızlı | Eğitim gerekir, sınırlı zeka |
| **Apple Intelligence / Foundation Models** | Apple entegre, güçlü | iOS 18.4+, cihaz sınırlı |
| **Kural Tabanlı Yorum Motoru** | Basit, güvenilir | "AI" hissi az |

**Önerilen Hibrit Yaklaşım:**
1. **Temel:** Kural tabanlı yorum motoru (JSON yorumlarını birleştir)
2. **Gelişmiş:** Apple Foundation Models (iOS 18.4+, iPhone 16+)
3. **Fallback:** Şablonlu cevap sistemi

### 4.2 Apple Foundation Models (iOS 18.4+)

```swift
// Core/AI/ChatEngine.swift
import FoundationModels  // iOS 18.4+

class AstroChatEngine: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    
    private let session: LanguageModelSession
    private var chart: BirthChart?
    
    init() {
        // Apple'ın on-device modelini kullan
        let instructions = """
        Sen deneyimli bir astrologsun. Kullanıcının doğum haritasına göre 
        sorularını yanıtla. Her zaman Türkçe cevap ver. Harita verileri 
        sana sağlanacak.
        """
        self.session = LanguageModelSession(instructions: instructions)
    }
    
    func setChart(_ chart: BirthChart) {
        self.chart = chart
    }
    
    func sendMessage(_ text: String) async {
        guard let chart = chart else { return }
        
        isProcessing = true
        messages.append(ChatMessage(role: .user, text: text))
        
        // Harita bağlamını mesaja ekle
        let contextualPrompt = """
        Kullanıcının doğum haritası:
        - Güneş: \(chart.sunSign.name) (\(chart.planets[0].degree)°)
        - Ay: \(chart.moonSign.name)
        - Yükselen: \(chart.ascendant.name)
        - Baskın Element: \(chart.dominantElement.name)
        - Evler: \(chart.houses.map { "Ev \($0.id): \($0.sign.name)" }.joined(separator: ", "))
        
        Kullanıcı sorusu: \(text)
        """
        
        do {
            let response = try await session.respond(to: contextualPrompt)
            messages.append(ChatMessage(role: .assistant, text: response.content))
        } catch {
            // Fallback: Kural tabanlı cevap
            let fallback = generateRuleBasedResponse(question: text, chart: chart)
            messages.append(ChatMessage(role: .assistant, text: fallback))
        }
        
        isProcessing = false
    }
    
    /// Fallback — şablon tabanlı cevap (Apple Intelligence yoksa)
    private func generateRuleBasedResponse(question: String, chart: BirthChart) -> String {
        let keywords = question.lowercased()
        
        if keywords.contains("aşk") || keywords.contains("ilişki") {
            let venus = chart.planets.first { $0.planet == .venus }!
            return """
            Venüs'ünüz \(venus.sign.name) burcunda ve \(venus.house). evde. \
            Bu, ilişkilerinizde \(venusInterpretation(venus)). \
            \(chart.aspects.filter { $0.planet1 == .venus || $0.planet2 == .venus }
                .map { aspectSummary($0) }.joined(separator: " "))
            """
        }
        
        if keywords.contains("kariyer") || keywords.contains("iş") {
            let mc = chart.houses[9] // 10. ev (Midheaven)
            return "10. eviniz \(mc.sign.name) burcunda. Bu, kariyerinizde..."
        }
        
        // Genel cevap
        return "Haritanıza göre \(chart.sunSign.name) Güneşi ve \(chart.moonSign.name) Ayı ile..."
    }
}
```

### 4.3 Sesli Etkileşim

```swift
// Core/AI/SpeechManager.swift
import Speech
import AVFoundation

class SpeechManager: NSObject, ObservableObject {
    
    @Published var isListening = false
    @Published var transcribedText = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))!
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()
    
    /// Sesli dinleme başlat
    func startListening() {
        // Mikrofon izni kontrol et
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { return }
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                self?.transcribedText = result.bestTranscription.formattedString
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isListening = true
    }
    
    /// Sesli dinlemeyi durdur
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        isListening = false
    }
    
    /// Metni sesli oku (Türkçe)
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}

// Features/AstroChat/VoiceInputButton.swift
struct VoiceInputButton: View {
    @ObservedObject var speech: SpeechManager
    var onTranscription: (String) -> Void
    
    var body: some View {
        Button {
            if speech.isListening {
                speech.stopListening()
                onTranscription(speech.transcribedText)
            } else {
                speech.startListening()
            }
        } label: {
            Image(systemName: speech.isListening ? "mic.fill" : "mic")
                .font(.title2)
                .foregroundStyle(speech.isListening ? .red : .white)
                .symbolEffect(.pulse, isActive: speech.isListening)
        }
    }
}
```

---

## 🧪 FAZ 5 — Test, Polish ve App Store (Hafta 15-16)

### 5.1 Test Stratejisi

```swift
// Tests/EphemerisTests.swift
// Bilinen doğum haritalarıyla hesaplama doğruluğunu test et
import XCTest

class EphemerisTests: XCTestCase {
    
    let engine = EphemerisManager.shared
    
    /// Bilinen bir haritayı doğrula
    /// Kaynak: astro.com'dan alınan referans değerler
    func testKnownChart_AlbertEinstein() {
        // 14 Mart 1879, 11:30, Ulm, Almanya (48.4°N, 10.0°E)
        let chart = engine.calculateBirthChart(
            date: makeDate(1879, 3, 14, 11, 30),
            latitude: 48.4,
            longitude: 10.0,
            timezone: TimeZone(identifier: "Europe/Berlin")!
        )
        
        XCTAssertEqual(chart.sunSign, .pisces)        // Balık
        XCTAssertEqual(chart.moonSign, .sagittarius)   // Yay
        XCTAssertEqual(chart.ascendant, .cancer)       // Yengeç
        
        // Güneş derecesi: ~23° Balık (±1° tolerans)
        let sunDeg = chart.planets.first { $0.planet == .sun }!.degree
        XCTAssertEqual(sunDeg, 23.0, accuracy: 1.0)
    }
}
```

### 5.2 App Store Checklist

```
□ App Store Connect'te app oluştur
□ In-App Purchase ürünlerini tanımla (₺200, ₺300, ₺400)
□ Sandbox test hesaplarıyla IAP test et
□ App Privacy Labels — lokasyon, satın alma verisi
□ Screenshots (6.7", 6.1", iPad)
□ App Preview videosu (opsiyonel ama önerilir)
□ Açıklama metni (Türkçe + İngilizce)
□ Age Rating: 4+ (astroloji → herkes için uygun)
□ Review Guidelines kontrolü:
    - 5.6: Reklam politikası uyumu
    - 3.1.1: In-App Purchase zorunlu (dijital içerik)
    - 2.3.1: Doğru açıklama — "eğlence amaçlı" ifadesi
□ Minimum 3 farklı cihazda test (SE, 15, 16 Pro)
□ Dark mode kontrolü
□ VoiceOver erişilebilirlik
□ Crash-free doğrulama (TestFlight beta)
```

---

## 📋 Claude Code ile Geliştirme Sırası

Her adımda Claude Code'a vereceğin prompt'lar:

### Hafta 1-2: Temel
```
1. "SwiftUI projesi oluştur, SwissEphemeris SPM paketi ekle"
2. "Planet, ZodiacSign, House, Aspect model'lerini yaz"
3. "EphemerisManager sınıfını yaz — gezegen pozisyonu ve ev hesaplama"
4. "Unit test: Einstein'ın haritasını doğrula"
```

### Hafta 3-4: Hesaplama + Veri
```
5. "Açı (aspect) hesaplama motorunu yaz"
6. "Element ve modalite dengesi hesaplama"
7. "JSON yorum dosyaları için şablon oluştur"
8. "InterpretationEngine yaz — harita + JSON → yorum"
```

### Hafta 5-7: UI
```
9.  "Canvas ile yıldız haritası wheel çiz — 12 burç halkası"
10. "Ev çizgileri ve gezegen sembollerini ekle"
11. "Açı çizgilerini çiz (renkli)"
12. "BirthDataInputView — tarih, saat, konum girişi"
13. "Doğum haritası sonuç ekranı — scroll, kartlar"
14. "Tarot modülü — kart çekme ve flip animasyonu"
15. "Günlük burç yorumu ekranı"
16. "Tasarım sistemi — kozmik tema, glassmorphism"
```

### Hafta 8-9: Monetizasyon
```
17. "StoreKit 2 ile In-App Purchase sistemi kur"
18. "Google AdMob rewarded ad entegrasyonu"
19. "EntitlementManager — özellik erişim kontrolü"
20. "Paywall ekranları tasarla"
```

### Hafta 10-12: AI + Ses
```
21. "Kural tabanlı soru-cevap motoru yaz"
22. "Apple Foundation Models entegrasyonu (iOS 18.4+)"
23. "Speech-to-Text ile sesli soru"
24. "Text-to-Speech ile sesli cevap"
25. "AstroChat ekranı — mesajlaşma UI"
```

### Hafta 13-14: Polish
```
26. "Animasyonlu yıldızlı arka plan"
27. "Onboarding flow — doğum bilgisi toplama"
28. "UserDefaults ile veri kaydetme"
29. "Erişilebilirlik (VoiceOver)"
30. "App Store metadata hazırla"
```

---

## 🔧 Teknik Gereksinimler Özeti

| Bileşen | Kütüphane/Framework | Kaynak |
|---------|---------------------|--------|
| Astroloji hesaplama | SwissEphemeris (SPM) | [GitHub](https://github.com/nicklauslitworker/SwissEphemeris) |
| UI | SwiftUI + Canvas | Apple |
| Yerel veri | JSON Bundle + UserDefaults | Apple |
| In-App Purchase | StoreKit 2 | Apple |
| Reklamlar | Google AdMob SDK | Google |
| Speech-to-Text | Speech Framework | Apple |
| Text-to-Speech | AVFoundation | Apple |
| On-device AI | Foundation Models (iOS 18.4+) | Apple |
| Grafik çizim | SwiftUI Canvas / Core Graphics | Apple |
| Konum → Koordinat | CoreLocation (geocoding) | Apple |

---

## ⚠️ Kritik Notlar

### Swiss Ephemeris Lisansı
- **GPL lisansı** altında. Ticari kullanım için ya GPL uyumlu olmalısın ya da Astrodienst'ten ticari lisans almalısın (~250 CHF).
- Alternatif: AA (Astronomical Algorithms) kitabından kendi hesaplama motorunu yazabilirsin ama bu çok daha zor.

### App Store Review Notları
- Apple, astroloji uygulamalarını "eğlence" kategorisinde kabul eder.
- "Bu uygulama eğlence amaçlıdır, profesyonel danışmanlık yerine geçmez" disclaimer'ı **şart**.
- Dijital içerik satışı (yorum, harita) **mutlaka** In-App Purchase ile olmalı. Harici ödeme linki yasak.

### Performans
- Swiss Ephemeris hesaplaması bir harita için ~50ms (çok hızlı).
- JSON yorumları lazy load et — tüm dosyaları aynı anda yükleme.
- Canvas çizimi `drawingGroup()` ile Metal'e offload et.

### Veri Boyutu Tahmini
- Ephemeris dosyaları: ~800KB
- JSON yorumlar (kapsamlı): ~2-5MB
- Tarot görselleri: ~10-15MB
- Burç/gezegen sembolleri (SVG): ~500KB
- **Toplam app boyutu: ~20-30MB** (çok makul)

---

## Faz 6: Gelismis Hesaplamalar (SwissEphemeris)

### 6.1 Hesaplama Bazli Ozellikler

| Ozellik | Aciklama | Oncelik |
|---------|----------|---------|
| **Transit Hesaplama** | Guncel gezegen konumlari vs natal harita — "Bugun Saturn senin Gunes'ine kare yapiyor" | Yuksek |
| **Solar Return** | Gunes'in natal konumuna dondugu an — yillik harita | Yuksek |
| **Lunar Return** | Ay'in natal konumuna dondugu an — aylik harita | Orta |
| **Secondary Progressions** | 1 gun = 1 yil ilkesiyle ilerletilmis harita | Orta |
| **Synastry (Gercek)** | Iki kisinin haritalarinin gercek karsilastirmasi (gezegen-gezegen acilari) | Yuksek |
| **Composite Chart** | Iki haritanin orta noktalarindan olusan iliski haritasi | Dusuk |

### 6.2 Ek Gok Cisimleri

| Ozellik | Aciklama | Oncelik |
|---------|----------|---------|
| **Lilith (Kara Ay)** | Ay'in yorungesinin en uzak noktasi — gizli arzular, bastirilan enerji | Yuksek |
| **Asteroidler** | Juno (evlilik), Pallas (strateji), Vesta (adanmislik), Ceres (beslenme) | Orta |
| **Sabit Yildizlar** | Regulus, Algol, Spica vb. — natal haritadaki etkiler | Dusuk |
| **Part of Fortune** | Talih Noktasi (ASC + Ay - Gunes) — sans ve basari alani | Yuksek |

### 6.3 Zaman Bazli Ozellikler

| Ozellik | Aciklama | Oncelik |
|---------|----------|---------|
| **Tutulma Hesaplama** | Gunes/Ay tutulma tarihleri ve natal haritaya etkisi | Orta |
| **Retrograde Donemleri** | Gezegenlerin retro baslangic/bitis tarihleri takvimi | Yuksek |
| **Void of Course Moon** | Ay'in boslukta oldugu zamanlar — karar almak icin uygun degil | Orta |
| **Gezegen Saatleri** | Gun ici planetary hours — her saatin yonetici gezegeni | Dusuk |

### 6.4 Uygulama Sirasi

1. **Transit hesaplama + UI** — Gunluk burcu gercek veriye dayandirma
2. **Lilith + Part of Fortune** — Natal haritaya ek noktalar
3. **Solar Return** — Yillik harita ozelligi
4. **Synastry (gercek harita)** — Uyum analizini iki harita uzerinden yapma
5. **Retrograde takvimi** — Gezegen retro donemleri goruntuleme
6. **Lunar Return + Progressions** — Ileri seviye astroloji
7. **Asteroidler + Sabit Yildizlar** — Derinlesmis harita analizi
8. **Composite Chart** — Iliski haritasi
9. **Tutulmalar + VOC Moon + Gezegen Saatleri** — Zaman bazli ozellikler

---

## Faz 7: Yeni Özellikler & Zenginleştirme

### 7.1 Doğum Haritası Paylaşımı (Öncelik: Yüksek)

Kullanıcının doğum haritasını güzel bir görsel olarak dışa aktarıp sosyal medyada paylaşabilmesi.

| Özellik | Açıklama |
|---------|----------|
| **Harita Görseli Export** | BirthChartWheelView'ı yüksek çözünürlüklü PNG'ye render et |
| **Instagram Story Template** | 1080x1920 kozmik tasarımlı şablon — büyük üçlü, gezegen pozisyonları |
| **ShareLink Entegrasyonu** | iOS share sheet ile tüm platformlara paylaşım |
| **Synastry Paylaşımı** | İki kişinin uyum sonucunu paylaşılabilir kart olarak export et |

**Neden Önemli:** Astroloji uygulamalarında organik büyümenin en büyük kaynağı sosyal paylaşım. Kullanıcılar haritalarını paylaştığında uygulamaya yeni kullanıcı çeker.

### 7.2 Astro Takvim / Günlük Planlayıcı (Öncelik: Yüksek)

Tüm mevcut gök olayı hesaplamalarını tek bir takvim görünümünde birleştir.

| Özellik | Açıklama |
|---------|----------|
| **Aylık Takvim Görünümü** | Ay fazları, retrograde, tutulmalar, VOC Moon tek ekranda |
| **Günlük Detay** | Seçilen günün transit açıları, gezegen saatleri, önerileri |
| **Kişiselleştirilmiş Öneriler** | Natal haritaya göre "Bugün iş görüşmesi için uygun" tarzı ipuçları |
| **Push Notification** | "Merkür retrograde başlıyor yarın!", "Ay burcuna giriyor" |

### 7.3 Aimed Solar Return — Discepolo (Öncelik: Orta)

Ciro Discepolo'nun en meşhur tekniği: Solar Return haritasını optimize eden seyahat lokasyonu bulma.

| Özellik | Açıklama |
|---------|----------|
| **Şehir Tarama** | Dünya üzerindeki şehirleri tarayarak SR haritasında kötü açıları minimize eden lokasyonu bul |
| **Harita Görselleştirme** | MapKit üzerinde "en iyi şehirler" pin'leri |
| **SR Karşılaştırma** | Mevcut lokasyon vs önerilen lokasyon SR harita karşılaştırması |

**Neden Önemli:** Piyasadaki çoğu uygulamada olmayan, ciddi bir farklılaştırıcı özellik.

### 7.4 Profection Year — Yıllık Tahmin (Öncelik: Orta)

| Özellik | Açıklama |
|---------|----------|
| **Aktif Ev Hesabı** | Kullanıcının yaşına göre aktif profection evini bul |
| **Lord Gezegen** | Aktif evin yönetici gezegenini ve natal konumunu göster |
| **Transit Bağlantısı** | Lord gezegenin aktif transitlerini mevcut transit sistemiyle birleştir |
| **Yıllık Tema** | Profection evine göre yılın ana temasını özetle |

### 7.5 Uygulama Sırası

1. **Doğum Haritası Paylaşımı** — Organik büyüme, hızlı implement
2. **Astro Takvim** — Mevcut verileri birleştirir, günlük kullanımı artırır
3. **Profection Year** — Basit ama değerli, transit sistemiyle entegre
4. **Aimed Solar Return** — En kapsamlı, Discepolo temasını güçlendirir
