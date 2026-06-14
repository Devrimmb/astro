import Foundation

/// Kullanıcının doğum haritası + bugünün gökyüzünden, astrolojik olarak
/// tutarlı, kişiselleştirilmiş günlük rehberlik üretir.
///
/// İçerik kompozisyoneldir: transit gezegenin kanonik teması + açının doğası
/// + natal noktanın yaşam alanı birleştirilerek mesaj kurulur. Uydurma kehanet
/// yoktur; klasik transit astrolojisi kurallarına dayanır.
struct DailyCosmicCoach: Sendable {

    // MARK: - Çıktı modelleri

    enum Tone: Sendable {
        case harmonik   // sekstil / üçgen — yeşil
        case zorlayici  // kare / karşıt — turuncu/kırmızı
        case notr       // kavuşum ve genel — accent
    }

    struct GuidanceItem: Identifiable, Sendable {
        let id = UUID()
        let icon: String      // SF Symbol adı
        let title: String     // kısa başlık (örn "Mars □ Güneş")
        let message: String   // koçluk cümlesi
        let tone: Tone
    }

    struct DailyGuidance: Sendable {
        let cosmicWeather: [GuidanceItem]    // genel — herkese aynı (o güne özel)
        let personalTransits: [GuidanceItem] // sana özel — natal transit açıları
        let moonMood: GuidanceItem?          // bugünün Ay teması (tek, hafif)

        var isEmpty: Bool {
            cosmicWeather.isEmpty && personalTransits.isEmpty && moonMood == nil
        }
    }

    // MARK: - Ana giriş

    static func guidance(
        natalChart: BirthChart?,
        date: Date,
        moonPhase: MoonPhaseInfo?,
        activeRetrogrades: [RetrogradeCalculator.RetrogradePeriod],
        isVOC: Bool,
        todayEclipses: [Eclipse]
    ) -> DailyGuidance {

        let weather = buildCosmicWeather(
            moonPhase: moonPhase,
            activeRetrogrades: activeRetrogrades,
            isVOC: isVOC,
            hasEclipse: !todayEclipses.isEmpty
        )

        guard let chart = natalChart else {
            return DailyGuidance(cosmicWeather: weather, personalTransits: [], moonMood: nil)
        }

        let report = TransitCalculator.calculate(natalChart: chart, transitDate: date)

        // Sadece majör açılar, Ay hariç ana liste
        let majorNonMoon = report.aspects.filter {
            $0.type.isMajor && $0.transitPlanet != .moon
        }

        // Önceliklendir, en güçlü 3'ü al
        let ranked: [TransitAspect] = Array(
            majorNonMoon.sorted { score($0) > score($1) }.prefix(3)
        )
        var personal: [GuidanceItem] = ranked.map {
            transitMessage($0, opener: isFast($0.transitPlanet) ? "Bugün" : "Bu dönem")
        }

        // Tutulmanın kişisel (natal'a yakın) etkisi → kişisel uyarıya yüksel
        for eclipse in todayEclipses {
            let affected = eclipse.affectsNatalPlanet(chart.planets, orb: 3.0)
                .filter { Planet.classicPlanets.contains($0) }
            if let planet = affected.first {
                personal.insert(eclipseMessage(eclipse: eclipse, natalPlanet: planet), at: 0)
            }
        }

        // Bugünün Ay teması: Ay'ın en güçlü majör natal açısı
        let moonAspect = report.aspects
            .filter { $0.transitPlanet == .moon && $0.type.isMajor }
            .sorted { $0.orb < $1.orb }
            .first
        let moonMood = moonAspect.map { moonMoodMessage($0, moonPhase: moonPhase) }

        return DailyGuidance(
            cosmicWeather: weather,
            personalTransits: personal,
            moonMood: moonMood
        )
    }

    // MARK: - Önceliklendirme

    /// Gezegen ağırlığı × açı yakınlığı (dar orb) × yaklaşan bonusu
    private static func score(_ a: TransitAspect) -> Double {
        let w = planetWeight(a.transitPlanet) + planetWeight(a.natalPlanet)
        let tightness = 1.0 / (a.orb + 0.5)
        let applyingBonus = a.applying ? 1.3 : 1.0
        return w * tightness * applyingBonus
    }

    private static func planetWeight(_ p: Planet) -> Double {
        switch p {
        case .sun, .moon: 5
        case .mercury, .venus, .mars: 4
        case .jupiter, .saturn: 3
        case .uranus, .neptune, .pluto: 2
        default: 1
        }
    }

    private static func isFast(_ p: Planet) -> Bool {
        switch p {
        case .sun, .moon, .mercury, .venus, .mars: true
        default: false
        }
    }

    // MARK: - Mesaj kurma

    private static func transitMessage(_ a: TransitAspect, opener: String?) -> GuidanceItem {
        let area = natalArea[a.natalPlanet] ?? "yaşam alanını"
        let verb: String
        switch a.type.nature {
        case .harmonik: verb = "akıcı biçimde destekliyor"
        case .zorlayici: verb = "zorluyor"
        case .notr: verb = "güçlü biçimde aktive ediyor" // kavuşum
        }
        let advice = adviceFor(transit: a.transitPlanet, tone: a.type.nature)

        let message: String
        if let opener {
            message = "\(opener) \(a.transitPlanet.name), \(area) \(verb). \(advice)"
        } else {
            message = "\(a.transitPlanet.name), \(area) \(verb). \(advice)"
        }
        let title = "\(a.transitPlanet.name) \(a.type.symbol) \(a.natalPlanet.name)"

        return GuidanceItem(
            icon: toneIcon(a.type.nature),
            title: title,
            message: message,
            tone: tone(for: a.type.nature)
        )
    }

    // MARK: - Public yorum API'si (Transit sayfası kullanır)

    /// Bir transit-natal açının kanonik yorumu. `today` true ise mesaj
    /// "Bugün/Bu dönem" ile başlar; false ise (geçmiş/gelecek tarih) nötr dil.
    static func aspectInterpretation(_ a: TransitAspect, today: Bool) -> GuidanceItem {
        let opener: String? = today ? (isFast(a.transitPlanet) ? "Bugün" : "Bu dönem") : nil
        return transitMessage(a, opener: opener)
    }

    /// Bir transit gezegenin natal evden geçişinin kanonik yorumu.
    /// "hayatının hangi alanı sahne alıyor" boyutu.
    static func houseTransitInterpretation(planet: Planet, house: Int) -> GuidanceItem? {
        guard Planet.classicPlanets.contains(planet),
              let area = houseArea[house] else { return nil }
        let message = "Transit \(planet.name) \(house). evinden geçiyor — \(area) \(houseEffect(planet))"
        return GuidanceItem(
            icon: "house.fill",
            title: "\(planet.name) · \(house). ev",
            message: message,
            tone: .notr
        )
    }

    private static func moonMoodMessage(_ a: TransitAspect, moonPhase: MoonPhaseInfo?) -> GuidanceItem {
        let area = natalArea[a.natalPlanet] ?? "iç dünyanı"
        let note: String
        switch a.type.nature {
        case .harmonik: note = "Duyguların akışta, içsel dengen güçlü."
        case .zorlayici: note = "Duyguların dalgalı olabilir; kendine alan tanı, tepkilerini yumuşat."
        case .notr: note = "Duyguların yoğun; iç sesini dinle."
        }
        let signNote = moonPhase?.moonSign.map { " Ay bugün \($0.name) burcunda." } ?? ""
        return GuidanceItem(
            icon: "moon.stars.fill",
            title: "Günün Ruh Hali",
            message: "Ay bugün \(area) tetikliyor. \(note)\(signNote)",
            tone: tone(for: a.type.nature)
        )
    }

    private static func eclipseMessage(eclipse: Eclipse, natalPlanet: Planet) -> GuidanceItem {
        let area = natalArea[natalPlanet] ?? "yaşam alanını"
        return GuidanceItem(
            icon: "sun.max.trianglebadge.exclamationmark",
            title: "Tutulma · \(natalPlanet.name)",
            message: "Bugünkü tutulma natal \(natalPlanet.name) noktana çok yakın — \(area) ilgilendiren konularda bu tutulma senin için özellikle güçlü. Önemli bir dönüm noktası gündeme gelebilir; ani kararlardan kaçın.",
            tone: .zorlayici
        )
    }

    // MARK: - Kozmik hava (genel)

    private static func buildCosmicWeather(
        moonPhase: MoonPhaseInfo?,
        activeRetrogrades: [RetrogradeCalculator.RetrogradePeriod],
        isVOC: Bool,
        hasEclipse: Bool
    ) -> [GuidanceItem] {
        var items: [GuidanceItem] = []

        if hasEclipse {
            items.append(GuidanceItem(
                icon: "sun.max.trianglebadge.exclamationmark",
                title: "Tutulma",
                message: "Tutulma enerjisi yoğun — derin dönüşüm zamanı. Ani kararlardan kaçın, akışa güven.",
                tone: .zorlayici
            ))
        }

        if isVOC {
            items.append(GuidanceItem(
                icon: "moon.haze",
                title: "Ay Boşlukta",
                message: "Ay boşlukta — yeni girişimler için uygun değil. Rutin işlere odaklan, önemli başlangıçları ertele.",
                tone: .notr
            ))
        }

        for planet in [Planet.mercury, .venus, .mars] where activeRetrogrades.contains(where: { $0.planet == planet }) {
            items.append(retroItem(planet))
        }

        if let phase = moonPhase?.phase {
            items.append(GuidanceItem(
                icon: moonPhaseIcon(phase),
                title: phase.name,
                message: moonPhaseAdvice(phase),
                tone: .notr
            ))
        }

        return items
    }

    private static func retroItem(_ planet: Planet) -> GuidanceItem {
        let message: String
        switch planet {
        case .mercury:
            message = "Merkür retro — iletişim, sözleşme ve teknolojide aksamalar olabilir. Mesajları iki kez kontrol et, önemli imzaları gözden geçir."
        case .venus:
            message = "Venüs retro — ilişkileri, değerleri ve harcamaları yeniden değerlendirme zamanı. Geçmişten biri gündeme gelebilir."
        case .mars:
            message = "Mars retro — enerji ve girişim gücü düşebilir. Yeni mücadeleler başlatmak yerine devam eden işleri gözden geçir."
        default:
            message = "\(planet.name) retro — bu temada içe dönüp gözden geçirme dönemi."
        }
        return GuidanceItem(
            icon: "arrow.backward.circle",
            title: "\(planet.name) Retro",
            message: message,
            tone: .zorlayici
        )
    }

    // MARK: - Kanonik tablolar

    /// Natal noktanın etkilenen yaşam alanı (iyelik ekli)
    private static let natalArea: [Planet: String] = [
        .sun: "kimliğini ve özgüvenini",
        .moon: "duygularını ve iç dünyanı",
        .mercury: "düşünce ve iletişim tarzını",
        .venus: "ilişkilerini ve keyiflerini",
        .mars: "enerjini ve eyleme geçişini",
        .jupiter: "büyüme ve inanç alanını",
        .saturn: "sorumluluklarını ve hayat yapını",
        .uranus: "özgürlük ve değişim alanını",
        .neptune: "hayal ve sezgi dünyanı",
        .pluto: "dönüşüm ve güç alanını"
    ]

    /// Natal evlerin yaşam alanı (transit ev geçişi yorumu için, iyelik ekli)
    private static let houseArea: [Int: String] = [
        1: "kimlik, görünüş ve yeni başlangıçlar alanını",
        2: "para, değerler ve güven alanını",
        3: "iletişim, öğrenme ve yakın çevre alanını",
        4: "ev, aile ve kökler alanını",
        5: "aşk, yaratıcılık ve eğlence alanını",
        6: "iş, sağlık ve günlük düzen alanını",
        7: "ilişkiler ve ortaklıklar alanını",
        8: "dönüşüm, ortak kaynaklar ve derinlik alanını",
        9: "yolculuk, inançlar ve yüksek öğrenim alanını",
        10: "kariyer, statü ve hedefler alanını",
        11: "arkadaşlar, topluluk ve gelecek alanını",
        12: "içe dönüş, ruhsallık ve bilinçaltı alanını"
    ]

    /// Transit gezegenin bir evden geçerken o alana kattığı kanonik etki
    private static func houseEffect(_ planet: Planet) -> String {
        switch planet {
        case .sun: "aydınlatıyor ve öne çıkarıyor; bu alana enerji ve odak geliyor."
        case .moon: "duygusal olarak öne çıkarıyor; bu alan şu an daha hassas (Ay hızlı geçer, etki kısa sürer)."
        case .mercury: "zihinsel olarak hareketlendiriyor; konuşmalar, kararlar ve planlar bu alanda yoğunlaşıyor."
        case .venus: "uyum ve keyif getiriyor; bu alanda ilişkiler ve hazlar öne çıkıyor."
        case .mars: "hareketlendiriyor; bu alanda enerji ve girişim yüksek ama sabırsızlığa dikkat."
        case .jupiter: "genişletiyor; bu alanda fırsat ve büyüme dönemi."
        case .saturn: "test ediyor ve yapılandırıyor; bu alanda sabır, sorumluluk ve emek gerekiyor."
        case .uranus: "sarsıyor ve yeniliyor; bu alanda beklenmedik değişimlere açık ol."
        case .neptune: "bulanıklaştırıyor ve ilham veriyor; bu alanda netlik azalabilir, sezgine güven."
        case .pluto: "derinden dönüştürüyor; bu alanda köklü ve kalıcı bir değişim süreci işliyor."
        default: "etkiliyor."
        }
    }

    /// Transit gezegenin doğasına ve açının tonuna göre koçluk cümlesi
    private static func adviceFor(transit: Planet, tone: AspectType.Nature) -> String {
        switch transit {
        case .sun:
            switch tone {
            case .harmonik: return "Özgüvenin ve canlılığın yüksek; kendini ortaya koymak için destekleyici bir gün."
            case .zorlayici: return "Ego ve irade gerginliği olabilir; kendini kanıtlama baskısını yumuşat."
            case .notr: return "Kimliğin ve odağın güçleniyor; niyetini netleştir."
            }
        case .moon:
            switch tone {
            case .harmonik: return "Duyguların akışta; sezgisel ve uyumlu hissedersin, yakınlık kurmak kolay."
            case .zorlayici: return "Duyguların dalgalı ve tepkisel olabilir; kendine alan tanı, anlık tepkilerden kaçın."
            case .notr: return "Duyguların yoğunlaşıyor; iç dünyana ve ihtiyaçlarına kulak ver."
            }
        case .mercury:
            switch tone {
            case .harmonik: return "İletişim ve öğrenme akıcı; konuşmalar, yazışmalar ve planlama için verimli bir gün."
            case .zorlayici: return "Yanlış anlaşılma ve dağınık düşünceye eğilim var; önemli mesajları iki kez kontrol et, acele konuşma."
            case .notr: return "Zihnin yoğun çalışıyor; fikirlerini netleştir ve not al."
            }
        case .venus:
            switch tone {
            case .harmonik: return "İlişkilerde uyum ve keyif öne çıkıyor; sevdiklerine yakınlaşmak için güzel bir gün."
            case .zorlayici: return "İlişkilerde değer ve beklenti gerginliği olabilir; küçük kırgınlıkları büyütme, uzlaşıya açık ol."
            case .notr: return "İlişki ve keyif arzun güçleniyor; neye değer verdiğini fark et."
            }
        case .mars:
            switch tone {
            case .harmonik: return "Cesaretin ve girişim gücün yüksek; harekete geçmek için iyi bir gün."
            case .zorlayici: return "Sabırsızlık ve çatışmaya açıksın; tepki vermeden önce dur, enerjini spora ya da fiziksel işe yönelt."
            case .notr: return "Eyleme geçme dürtün güçlü; enerjini net bir hedefe kanalize et."
            }
        case .jupiter:
            switch tone {
            case .harmonik: return "Şans, iyimserlik ve büyüme fırsatları destekleniyor; ufkunu genişletmeye açık ol."
            case .zorlayici: return "Aşırı iyimserlik ya da abartıya kaçabilirsin; söz verirken ölçülü ol."
            case .notr: return "Büyüme ve genişleme isteğin artıyor; fırsatları gözden geçir."
            }
        case .saturn:
            switch tone {
            case .harmonik: return "Disiplin ve sabır meyvesini veriyor; uzun vadeli işler için sağlam bir dönem."
            case .zorlayici: return "Sorumluluk, sınır ve engel hissi yoğun olabilir; sabırlı ol, adım adım ilerle."
            case .notr: return "Yapı kurma ve sorumluluk alma zamanı; gerçekçi planlar yap."
            }
        case .uranus:
            switch tone {
            case .harmonik: return "Beklenmedik fırsatlar ve özgürleştirici fikirler akabilir; esnek ol."
            case .zorlayici: return "Ani değişim ve huzursuzluk olabilir; sabit kalma ihtiyacını esnetmek rahatlatır."
            case .notr: return "Değişim ve özgünlük isteğin güçleniyor; rutini kırmaya açık ol."
            }
        case .neptune:
            switch tone {
            case .harmonik: return "Sezgi, ilham ve şefkat güçlü; yaratıcı ve ruhsal işler için verimli bir dönem."
            case .zorlayici: return "Kafa karışıklığı ya da net görememe olabilir; önemli kararları erteleyebilirsin."
            case .notr: return "Hayal gücün ve sezgin yoğunlaşıyor; ilhama açık ol ama gerçekliği elden bırakma."
            }
        case .pluto:
            switch tone {
            case .harmonik: return "Derin dönüşüm ve içsel güç destekleniyor; köklü değişimlere açıksın."
            case .zorlayici: return "Kontrol ve güç gerginliği olabilir; bırakman gerekene tutunma."
            case .notr: return "Dönüşüm ve yenilenme süreci derinleşiyor; eskiyi bırakmaya hazır ol."
            }
        default:
            return "Günün enerjisini fark ederek ilerle."
        }
    }

    private static func toneIcon(_ nature: AspectType.Nature) -> String {
        switch nature {
        case .harmonik: "checkmark.seal.fill"
        case .zorlayici: "exclamationmark.triangle.fill"
        case .notr: "circle.hexagonpath.fill"
        }
    }

    private static func tone(for nature: AspectType.Nature) -> Tone {
        switch nature {
        case .harmonik: .harmonik
        case .zorlayici: .zorlayici
        case .notr: .notr
        }
    }

    private static func moonPhaseIcon(_ phase: MoonPhaseName) -> String {
        switch phase {
        case .newMoon: "moonphase.new.moon"
        case .waxingCrescent: "moonphase.waxing.crescent"
        case .firstQuarter: "moonphase.first.quarter"
        case .waxingGibbous: "moonphase.waxing.gibbous"
        case .fullMoon: "moonphase.full.moon"
        case .waningGibbous: "moonphase.waning.gibbous"
        case .lastQuarter: "moonphase.last.quarter"
        case .waningCrescent: "moonphase.waning.crescent"
        }
    }

    private static func moonPhaseAdvice(_ phase: MoonPhaseName) -> String {
        switch phase {
        case .newMoon: "Yeni Ay — niyet belirleme ve yeni başlangıçlar için ideal gün."
        case .waxingCrescent: "Büyüyen Hilal — planlarını harekete geçir, ilk adımları at."
        case .firstQuarter: "İlk Dördün — engelleri aşma zamanı, kararlılıkla ilerle."
        case .waxingGibbous: "Büyüyen Şişkin Ay — detaylara odaklan, ince ayar yap."
        case .fullMoon: "Dolunay — sonuçlar ortaya çıkıyor; kutlama ve şükran zamanı."
        case .waningGibbous: "Küçülen Şişkin Ay — paylaşma ve öğretme enerjisi güçlü."
        case .lastQuarter: "Son Dördün — bırakma zamanı, artık işe yaramayanı serbest bırak."
        case .waningCrescent: "Küçülen Hilal — dinlenme, meditasyon ve içe dönüş zamanı."
        }
    }
}
