import Foundation

enum DailyTipGenerator {
    static func generate(
        moonPhase: MoonPhaseInfo?,
        isVOC: Bool,
        activeRetrogrades: [RetrogradeCalculator.RetrogradePeriod],
        hasEclipse: Bool
    ) -> String {
        if hasEclipse {
            return "Tutulma enerjisi yoğun — derin dönüşüm zamanı. Ani kararlardan kaçının."
        }

        if isVOC {
            return "Ay boşlukta — yeni girişimler için uygun değil. Rutin işlere odaklanın."
        }

        let mercuryRetro = activeRetrogrades.contains { $0.planet == .mercury }
        if mercuryRetro {
            return "Merkür retrograde — iletişimde dikkatli olun, sözleşmeleri gözden geçirin."
        }

        let venusRetro = activeRetrogrades.contains { $0.planet == .venus }
        if venusRetro {
            return "Venüs retrograde — eski ilişkileri yeniden değerlendirme zamanı."
        }

        guard let phase = moonPhase?.phase else {
            return "Günün enerjisini takip edin."
        }

        switch phase {
        case .newMoon:
            return "Yeni Ay — niyet belirleme ve yeni başlangıçlar için ideal gün."
        case .waxingCrescent:
            return "Büyüyen Hilal — planlarınızı harekete geçirin, ilk adımları atın."
        case .firstQuarter:
            return "İlk Dördün — engelleri aşma zamanı, kararlılıkla ilerleyin."
        case .waxingGibbous:
            return "Büyüyen Şişkin Ay — detaylara odaklanın, ince ayar yapın."
        case .fullMoon:
            return "Dolunay — sonuçlar ortaya çıkıyor. Kutlama ve şükran zamanı."
        case .waningGibbous:
            return "Küçülen Şişkin Ay — paylaşma ve öğretme enerjisi güçlü."
        case .lastQuarter:
            return "Son Dördün — bırakma zamanı, artık işe yaramayanı serbest bırakın."
        case .waningCrescent:
            return "Küçülen Hilal — dinlenme, meditasyon ve içe dönüş zamanı."
        }
    }
}
