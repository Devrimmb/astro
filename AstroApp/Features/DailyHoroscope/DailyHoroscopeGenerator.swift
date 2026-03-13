import Foundation

enum DailyHoroscopeGenerator {

    static func generate(for sign: ZodiacSign, date: Date) -> DailyHoroscope {
        // Tarih + burç bazlı deterministik seed
        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let seed = day * 13 + sign.rawValue * 37 + year * 7

        func rating(_ offset: Int) -> Int {
            ((seed + offset * 11) % 5) + 1
        }

        let overall = rating(0)
        let love = rating(1)
        let career = rating(2)
        let health = rating(3)
        let luck = rating(4)

        let generalTexts = textsForSign(sign)
        let generalIndex = seed % generalTexts.count
        let adviceIndex = (seed + 7) % advices.count
        let colorIndex = (seed + 3) % colors.count
        let luckyNum = ((seed * 7 + 13) % 99) + 1

        return DailyHoroscope(
            sign: sign,
            date: date,
            generalText: generalTexts[generalIndex],
            advice: advices[adviceIndex],
            overallRating: overall,
            loveRating: love,
            careerRating: career,
            healthRating: health,
            luckRating: luck,
            luckyColor: colors[colorIndex],
            luckyNumber: luckyNum
        )
    }

    // MARK: - Burca Özel Metinler

    private static func textsForSign(_ sign: ZodiacSign) -> [String] {
        switch sign.element {
        case .fire:
            return [
                "Bugün enerjiniz yüksek ve harekete geçme zamanı. Cesur kararlar almaktan çekinmeyin, yıldızlar sizden yana. Liderlik özellikleriniz ön plana çıkıyor.",
                "İçinizdeki ateş bugün parlak yanıyor. Yeni projelere başlamak için ideal bir gün. Motivasyonunuz çevrenize de ilham verecek.",
                "Rekabetçi ruhunuz bugün güçlü. Spor veya fiziksel aktivite enerjinizi dengelemenize yardımcı olacak. Sabırsızlıktan kaçının.",
                "Bugün spontane kararlar şansınızı açabilir. Rutininizi kırmaktan korkmayın, beklenmedik fırsatlar kapınızda olabilir.",
                "Yaratıcı enerjiniz dorukta. Sanatsal projeler veya yeni hobiler keşfetmek için harika bir gün. Tutkularınızı takip edin.",
            ]
        case .earth:
            return [
                "Bugün pratik düşünceleriniz sizi ileriye taşıyacak. Finansal konularda dikkatli adımlar atmanın zamanı. Sabırlı olun, sonuçlar gelecek.",
                "Günlük rutininize odaklanın, küçük detaylar büyük farklar yaratacak. İş hayatında disiplininiz ödüllendirilecek.",
                "Maddi konularda olumlu gelişmeler olası. Uzun vadeli planlarınızı gözden geçirin. Sağlığınıza ekstra özen gösterin.",
                "Bugün ayaklarınız yere sağlam basıyor. Güvenilirliğiniz çevrenizde takdir görüyor. Doğayla vakit geçirmek iyi gelecek.",
                "Somut sonuçlar elde edeceğiniz bir gün. Planlı çalışma meyvelerini verecek. Kendinizi şımartmak için küçük bir ödül düşünün.",
            ]
        case .air:
            return [
                "İletişim yetenekleriniz bugün zirve yapıyor. Sosyal çevrenizde yeni bağlantılar kurabilirsiniz. Fikirlerinizi paylaşmaktan çekinmeyin.",
                "Zihinsel enerjiniz yüksek, yeni bilgiler öğrenmek için harika bir gün. Kitap, podcast veya kurs ile kendinizi geliştirin.",
                "Bugün sosyal medya veya iletişim kanalları üzerinden güzel haberler gelebilir. Ağınızı genişletmenin tam zamanı.",
                "Merakınız sizi yeni keşiflere götürecek. Farklı bakış açılarına açık olun, beklenmedik çözümler bulabilirsiniz.",
                "Bugün kelimeleriniz güçlü. Yazı yazmak, konuşma yapmak veya düşüncelerinizi ifade etmek için ideal bir gün.",
            ]
        case .water:
            return [
                "Sezgileriniz bugün çok güçlü, iç sesinizi dinleyin. Duygusal derinliğiniz ilişkilerinize anlam katacak. Kendinize zaman ayırın.",
                "Rüyalarınız ve sezgileriniz önemli mesajlar taşıyor olabilir. Meditasyon veya günlük tutmak faydalı olacak.",
                "Duygusal bağlarınız bugün güçleniyor. Sevdiklerinizle kaliteli vakit geçirin. Empati yeteneğiniz sizi öne çıkarıyor.",
                "İç dünyanız bugün zengin ve derin. Sanatsal aktiviteler ruhunuzu besleyecek. Sınırlarınızı korumayı unutmayın.",
                "Bugün duygusal zekânız yüksek. Başkalarının hislerini kolayca anlıyorsunuz. Bu yeteneği iyi niyetle kullanın.",
            ]
        }
    }

    // MARK: - Genel Tavsiyeler

    private static let advices = [
        "Bugün kendinize nazik olun. Küçük molalar verin ve nefes egzersizleri yapın.",
        "Yeni bir şey denemekten korkmayın. Konfor alanınızın dışına çıkmak size iyi gelecek.",
        "Bir arkadaşınızı arayın veya mesaj atın. Sosyal bağlar ruh sağlığınız için önemli.",
        "Doğada yürüyüş yapın veya açık havada vakit geçirin. Doğa enerjinizi yenileyecek.",
        "Günlük tutmak veya düşüncelerinizi yazmak bugün özellikle faydalı olacak.",
        "Sağlıklı beslenmeye özen gösterin. Vücudunuz size ne söylüyor, dinleyin.",
        "Minnettarlık listesi yapın. Sahip olduklarınıza odaklanmak pozitif enerji çekecek.",
        "Yaratıcı bir aktivite ile kendinizi ifade edin — çizim, müzik, yemek pişirme.",
        "Bugün ertelediğiniz bir işi tamamlayın. Küçük başarılar büyük motivasyon yaratır.",
        "Su içmeyi ve düzenli uyumayı ihmal etmeyin. Temel ihtiyaçlar enerjinizin temelidir.",
        "Bir kitap açın veya yeni bir podcast keşfedin. Zihinsel beslenme bugün önemli.",
        "Hayır demeyi öğrenin. Sınırlarınız sizi korur, başkalarını da saygıya davet eder.",
    ]

    // MARK: - Renkler

    private static let colors = [
        "Mor", "Mavi", "Yeşil", "Turuncu", "Kırmızı", "Altın",
        "Gümüş", "Pembe", "Turkuaz", "Lacivert", "Beyaz", "Bordo",
    ]
}
