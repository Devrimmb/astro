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
                    bigThreeItem(label: "Güneş", sign: chart.sunSign, icon: "sun.max.fill", color: .orange)
                    bigThreeItem(label: "Ay", sign: chart.moonSign, icon: "moon.fill", color: Color(red: 0.35, green: 0.78, blue: 0.98))
                    bigThreeItem(label: "Yükselen", sign: chart.ascendant, icon: "arrow.up.circle.fill", color: accentColor)
                }
            }
        }
    }

    // MARK: - Element & Modalite

    @ViewBuilder
    private var elementModalitySection: some View {
        if let element = chart.dominantElement, let modality = chart.dominantModality {
            pdfCard {
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Baskın Element")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(element.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 1, height: 30)

                    VStack(spacing: 4) {
                        Text("Baskın Modalite")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(modality.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Gezegen Pozisyonları

    private var planetPositionsSection: some View {
        pdfCard {
            VStack(alignment: .leading, spacing: 6) {
                sectionTitle("Gezegen Pozisyonları")

                // Başlık satırı
                HStack {
                    Text("Gezegen")
                        .frame(width: 80, alignment: .leading)
                    Text("Burç")
                        .frame(width: 90, alignment: .leading)
                    Text("Derece")
                        .frame(width: 45, alignment: .trailing)
                    Text("Ev")
                        .frame(width: 30, alignment: .center)
                    Spacer()
                }
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))

                ForEach(chart.planets) { position in
                    HStack {
                        Text(position.planet.name)
                            .frame(width: 80, alignment: .leading)
                        HStack(spacing: 3) {
                            Text(position.sign.glyph)
                            Text(position.sign.name)
                        }
                        .frame(width: 90, alignment: .leading)
                        Text(String(format: "%.1f°", position.degree))
                            .frame(width: 45, alignment: .trailing)
                        Text("\(position.house)")
                            .frame(width: 30, alignment: .center)
                        if position.isRetrograde {
                            Text("℞")
                                .foregroundStyle(Color(red: 1.0, green: 0.40, blue: 0.45))
                                .font(.system(size: 9, weight: .bold))
                        }
                        Spacer()
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

    // MARK: - Evler

    private var housesSection: some View {
        pdfCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("Evler")

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 6) {
                    ForEach(chart.houses) { house in
                        VStack(spacing: 2) {
                            Text("\(house.id). Ev")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                            Text(house.sign.glyph)
                                .font(.system(size: 18))
                            Text(house.sign.name)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white)
                            Text(String(format: "%.0f°", house.degree))
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.03), in: .rect(cornerRadius: 8))
                    }
                }
            }
        }
    }

    // MARK: - Açılar

    @ViewBuilder
    private var aspectsSection: some View {
        if !chart.aspects.isEmpty {
            pdfCard {
                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle("Açılar")

                    ForEach(Array(chart.aspects.enumerated()), id: \.offset) { _, aspect in
                        HStack {
                            Text(aspect.planet1.name)
                                .frame(width: 72, alignment: .leading)
                            Text(aspectSymbol(aspect.type))
                                .frame(width: 16)
                            Text(aspect.planet2.name)
                                .frame(width: 72, alignment: .leading)
                            Spacer()
                            Text(String(format: "%.1f°", aspect.orb))
                                .foregroundStyle(.white.opacity(0.4))
                            Circle()
                                .fill(aspectNatureColor(aspect.type.nature))
                                .frame(width: 5, height: 5)
                        }
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
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

    private func aspectSymbol(_ type: AspectType) -> String {
        switch type {
        case .conjunction: "☌"
        case .sextile: "⚹"
        case .square: "□"
        case .trine: "△"
        case .opposition: "☍"
        }
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
        case .bigThree: .orange
        case .planetInSign: Color(red: 0.56, green: 0.44, blue: 1.0)
        case .planetInHouse: Color(red: 0.35, green: 0.78, blue: 0.98)
        case .houseInSign: .teal
        case .aspect: .orange
        case .element: Color(red: 1.0, green: 0.40, blue: 0.45)
        case .modality: .gray
        }
    }
}
