import SwiftUI
import UIKit

/// Doğum haritasının tüm içeriğini (çark, gezegenler, evler, açılar, yorumlar)
/// PDF olarak dışa aktarır.
enum ChartPDFExporter {

    @MainActor
    static func exportAndShare(chart: BirthChart, ownerName: String, interpretation: InterpretationEngine) {
        let view = ChartPDFContentView(
            chart: chart,
            ownerName: ownerName,
            interpretationSections: interpretation.interpret(chart: chart).sections
        )

        guard let pdfData = renderToPDF(view) else { return }

        let safeName = ownerName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        let fileName = "dogum_haritasi_\(safeName).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: tempURL)

        presentShareSheet(items: [tempURL])
    }

    @MainActor
    private static func renderToPDF<V: View>(_ view: V) -> Data? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: 595, height: nil)

        let pdfData = NSMutableData()

        renderer.render { size, renderInContext in
            let bounds = CGRect(origin: .zero, size: size)

            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
                return
            }

            var mediaBox = bounds
            context.beginPage(mediaBox: &mediaBox)
            renderInContext(context)
            context.endPage()
            context.closePDF()
        }

        return pdfData.count > 0 ? pdfData as Data : nil
    }

    private static func presentShareSheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        topVC.present(activityVC, animated: true)
    }
}

// MARK: - PDF İçerik View'ı

/// PDF için tüm harita bilgilerini içeren view.
private struct ChartPDFContentView: View {
    let chart: BirthChart
    let ownerName: String
    let interpretationSections: [InterpretationSection]

    private let accentColor = Color(red: 0.56, green: 0.44, blue: 1.0)
    private let bgColor = Color(red: 0.04, green: 0.05, blue: 0.12)
    private let cardBg = Color.white.opacity(0.06)
    private let borderColor = Color.white.opacity(0.08)

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            chartWheelSection
            bigThreeSection
            elementModalitySection
            planetPositionsSection
            housesSection
            houseInterpretationsSection
            aspectsSection
            interpretationsSection
            footerSection
        }
        .padding(24)
        .frame(width: 595)
        .background(bgColor)
    }

    // MARK: - Başlık

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .foregroundStyle(accentColor)
                Text("AstroApp")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.bottom, 4)

            Text("✦ DOĞUM HARİTASI ✦")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .tracking(3)

            if !ownerName.isEmpty {
                Text(ownerName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            Text(formattedBirthDate)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.top, 12)
    }

    // MARK: - Harita Çarkı

    private var chartWheelSection: some View {
        ChartWheelView(chart: chart, size: 280)
            .padding(.vertical, 8)
    }

    // MARK: - Büyük Üçlü

    private var bigThreeSection: some View {
        pdfCard {
            VStack(spacing: 10) {
                Text("Büyük Üçlü")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 0) {
                    bigThreeItem(label: "Güneş", sign: chart.sunSign, icon: "sun.max.fill", color: AstroTheme.planet(.sun))
                    bigThreeItem(label: "Ay", sign: chart.moonSign, icon: "moon.fill", color: Color(red: 0.35, green: 0.78, blue: 0.98))
                    bigThreeItem(label: "Yükselen", sign: chart.ascendant, icon: "arrow.up.circle.fill", color: accentColor)
                }
            }
        }
    }

    // MARK: - Element & Modalite

    private var elementModalitySection: some View {
        let elements = chart.elementBalance
        let modalities = chart.modalityBalance
        let totalScore = elements.values.reduce(0, +)

        return pdfCard {
            VStack(spacing: 12) {
                Text("Element & Modalite Dengesi")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)

                // Element progress bar'ları
                VStack(spacing: 6) {
                    ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                        let count = elements[element, default: 0]
                        let ratio = totalScore > 0 ? count / totalScore : 0

                        HStack(spacing: 8) {
                            Text(pdfElementIcon(element))
                                .font(.system(size: 14))
                                .frame(width: 20)

                            Text(element.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 42, alignment: .leading)

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(.white.opacity(0.08))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(pdfElementColor(element))
                                        .frame(width: max(4, geo.size.width * ratio))
                                }
                            }
                            .frame(height: 8)

                            Text("%\(Int((ratio * 100).rounded()))")
                                .font(.system(size: 11, weight: .bold).monospacedDigit())
                                .foregroundStyle(pdfElementColor(element))
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }

                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(height: 1)
                    .padding(.horizontal, 8)

                // Modaliteler
                HStack(spacing: 0) {
                    ForEach(ZodiacSign.Modality.allCases, id: \.self) { modality in
                        let count = modalities[modality, default: 0]

                        VStack(spacing: 4) {
                            Text(pdfModalityIcon(modality))
                                .font(.system(size: 14))
                            Text(modality.displayName)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(count)")
                                .font(.system(size: 16, weight: .bold).monospacedDigit())
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func pdfElementIcon(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire: "🔥"
        case .earth: "🌍"
        case .air: "💨"
        case .water: "💧"
        }
    }

    private func pdfElementColor(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire: Color(red: 1.0, green: 0.40, blue: 0.45)
        case .earth: AstroTheme.harmonik
        case .air: AstroTheme.planet(.sun)
        case .water: AstroTheme.water
        }
    }

    private func pdfModalityIcon(_ modality: ZodiacSign.Modality) -> String {
        switch modality {
        case .cardinal: "⚡"
        case .fixed: "🪨"
        case .mutable: "🌀"
        }
    }

    // MARK: - Gezegen Pozisyonları

    private var planetPositionsSection: some View {
        pdfCard {
            VStack(alignment: .leading, spacing: 6) {
                sectionTitle("Gezegen Pozisyonları")

                // Başlık satırı
                HStack(spacing: 0) {
                    Text("Gezegen")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Burç")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Derece")
                        .frame(width: 50, alignment: .trailing)
                    Text("Ev")
                        .frame(width: 30, alignment: .center)
                    Text("")
                        .frame(width: 16)
                }
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))

                ForEach(chart.planets) { position in
                    HStack(spacing: 0) {
                        Text(position.planet.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 3) {
                            Text(position.sign.glyph)
                            Text(position.sign.name)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "%.1f°", position.degree))
                            .frame(width: 50, alignment: .trailing)
                        Text("\(position.house)")
                            .frame(width: 30, alignment: .center)
                        if position.isRetrograde {
                            Text("℞")
                                .foregroundStyle(Color(red: 1.0, green: 0.40, blue: 0.45))
                                .font(.system(size: 9, weight: .bold))
                                .frame(width: 16)
                        } else {
                            Spacer().frame(width: 16)
                        }
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.8))

                    if position.planet != chart.planets.last?.planet {
                        Rectangle()
                            .fill(.white.opacity(0.04))
                            .frame(height: 0.5)
                    }
                }
            }
        }
    }

    // MARK: - Evler (Özet Grid)

    private var housesSection: some View {
        pdfCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("Evler")

                // 2 sütunlu kompakt grid
                let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 2)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(chart.houses) { house in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Text(house.sign.glyph)
                                    .font(.system(size: 13))
                                Text("\(house.id). Ev")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("— \(house.sign.name)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                                Spacer()
                                Text(String(format: "%.0f°", house.degree))
                                    .font(.system(size: 8))
                                    .foregroundStyle(.white.opacity(0.35))
                            }

                            if !house.planets.isEmpty {
                                Text(house.planets.map { $0.planet.name }.joined(separator: ", "))
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundStyle(accentColor.opacity(0.8))
                            }
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.03), in: .rect(cornerRadius: 6))
                    }
                }
            }
        }
    }

    // MARK: - Ev Yorumları (Detay)

    private var houseInterpretationsSection: some View {
        pdfCard {
            VStack(alignment: .leading, spacing: 6) {
                sectionTitle("Ev Yorumları")

                ForEach(chart.houses) { house in
                    if let entry = HouseSignInterpretation.interpretation(house: house.id, zodiacSign: house.sign) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 3) {
                                Text(house.sign.glyph)
                                    .font(.system(size: 10))
                                Text("\(house.id). Ev — \(house.sign.name)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Text(entry.description)
                                .font(.system(size: 7.5))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineSpacing(1)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.03), in: .rect(cornerRadius: 6))
                    }
                }
            }
        }
    }

    // MARK: - Açılar (Grid + Liste)

    @ViewBuilder
    private var aspectsSection: some View {
        if !chart.aspects.isEmpty {
            // Açı Grid Matrisi
            pdfCard {
                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle("Açı Tablosu")
                    pdfAspectGrid
                }
            }

            // Açı Listesi
            pdfCard {
                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle("Açılar")

                    ForEach(Array(chart.aspects.enumerated()), id: \.offset) { _, aspect in
                        HStack(spacing: 0) {
                            Text(aspect.point1.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(aspect.type.symbol)
                                .frame(width: 16)
                            Text(aspect.point2.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(String(format: "%.1f°", aspect.orb))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 36, alignment: .trailing)
                            Circle()
                                .fill(aspectNatureColor(aspect.type.nature))
                                .frame(width: 5, height: 5)
                                .padding(.leading, 4)
                        }
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    /// PDF için üçgen açı matrisi
    private var pdfAspectGrid: some View {
        let points = pdfGridPoints
        let lookup = pdfAspectLookup

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(1..<points.count, id: \.self) { row in
                HStack(spacing: 0) {
                    Text(points[row].glyph)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 20)

                    ForEach(0..<row, id: \.self) { col in
                        let key = "\(points[row])_\(points[col])"
                        if let aspect = lookup[key] {
                            pdfGridCell(aspect)
                        } else {
                            Color.clear
                                .frame(width: 24, height: 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(.white.opacity(0.03), lineWidth: 0.3)
                                )
                        }
                    }
                }
            }

            // Alt sütun başlıkları
            HStack(spacing: 0) {
                Color.clear.frame(width: 24, height: 14)
                ForEach(0..<(points.count - 1), id: \.self) { col in
                    Text(points[col].glyph)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 14)
                }
            }
        }
    }

    private func pdfGridCell(_ aspect: Aspect) -> some View {
        let bgColor: Color = switch aspect.type.nature {
        case .harmonik: Color(red: 0.30, green: 0.85, blue: 0.65)
        case .zorlayici: Color(red: 1.0, green: 0.40, blue: 0.45)
        case .notr: Color(red: 0.35, green: 0.78, blue: 0.98)
        }

        return VStack(spacing: 0) {
            Text(aspect.type.symbol)
                .font(.system(size: 7))
                .foregroundStyle(bgColor)
            Text(String(format: "%.0f", aspect.orb))
                .font(.system(size: 5))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(width: 24, height: 20)
        .background(bgColor.opacity(0.1), in: .rect(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(.white.opacity(0.06), lineWidth: 0.3)
        )
    }

    private var pdfGridPoints: [ChartPoint] {
        var result: [ChartPoint] = []
        for planet in Planet.classicPlanets {
            if chart.planets.contains(where: { $0.planet == planet }) {
                result.append(.planet(planet))
            }
        }
        for extra in [Planet.northNode, .chiron] {
            if chart.planets.contains(where: { $0.planet == extra }) {
                result.append(.planet(extra))
            }
        }
        if chart.houses.contains(where: { $0.id == 1 }) {
            result.append(.ascendant)
        }
        if chart.houses.contains(where: { $0.id == 10 }) {
            result.append(.midheaven)
        }
        return result
    }

    private var pdfAspectLookup: [String: Aspect] {
        var dict: [String: Aspect] = [:]
        for aspect in chart.aspects {
            dict["\(aspect.point1)_\(aspect.point2)"] = aspect
            dict["\(aspect.point2)_\(aspect.point1)"] = aspect
        }
        return dict
    }

    // MARK: - Yorumlar

    @ViewBuilder
    private var interpretationsSection: some View {
        if !interpretationSections.isEmpty {
            pdfCard {
                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Yorumlar")

                    ForEach(interpretationSections) { section in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(categoryColor(section.category))
                                    .frame(width: 5, height: 5)
                                Text(section.title)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            Text(section.body)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.65))
                                .lineSpacing(2)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.03), in: .rect(cornerRadius: 8))
                    }
                }
            }
        }
    }

    // MARK: - Alt Bilgi

    private var footerSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle")
                .foregroundStyle(accentColor)
            Text("AstroApp")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Yardımcılar

    private func pdfCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBg, in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 0.5)
            }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.bottom, 4)
    }

    private func bigThreeItem(label: String, sign: ZodiacSign?, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            if let sign {
                Text(sign.glyph)
                    .font(.system(size: 22))
                Text(sign.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: chart.birthDate)
    }

    private func aspectNatureColor(_ nature: AspectType.Nature) -> Color {
        switch nature {
        case .harmonik: Color(red: 0.30, green: 0.85, blue: 0.65)
        case .zorlayici: Color(red: 1.0, green: 0.40, blue: 0.45)
        case .notr: Color(red: 0.35, green: 0.78, blue: 0.98)
        }
    }

    private func categoryColor(_ category: InterpretationCategory) -> Color {
        switch category {
        case .bigThree: AstroTheme.planet(.sun)
        case .planetInHouseSign: AstroTheme.accent
        case .houseInSign: AstroTheme.accentSecondary
        case .aspect: AstroTheme.planet(.sun)
        case .element: Color(red: 1.0, green: 0.40, blue: 0.45)
        case .modality: AstroTheme.textSecondary
        }
    }
}
