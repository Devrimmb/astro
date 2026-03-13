import SwiftUI

/// SwiftUI view'larını paylaşılabilir UIImage'e çevirir ve share sheet açar.
enum ShareImageRenderer {

    /// Doğum haritası görseli render edip paylaşım sheet'i açar.
    @MainActor
    static func shareChart(chart: BirthChart, ownerName: String) {
        let view = ChartShareCard(chart: chart, ownerName: ownerName)
        guard let image = renderToImage(view) else { return }
        presentShareSheet(items: [image])
    }

    /// Synastry görseli render edip paylaşım sheet'i açar.
    @MainActor
    static func shareSynastry(
        person1Name: String,
        person2Name: String,
        result: SynastryResult
    ) {
        let view = SynastryShareCard(
            person1Name: person1Name,
            person2Name: person2Name,
            discopoloScore: result.relationshipScore.scoreValue,
            discopoloDescription: result.relationshipScore.scoreDescription.rawValue,
            aspectScore: result.aspectBasedScore,
            emotionalScore: result.emotionalScore,
            communicationScore: result.communicationScore,
            passionScore: result.passionScore,
            stabilityScore: result.stabilityScore
        )
        guard let image = renderToImage(view) else { return }
        presentShareSheet(items: [image])
    }

    /// Transit görseli render edip paylaşım sheet'i açar.
    @MainActor
    static func shareTransit(personName: String, date: Date, report: TransitReport) {
        let view = TransitShareCard(personName: personName, date: date, report: report)
        guard let image = renderToImage(view) else { return }
        presentShareSheet(items: [image])
    }

    /// Solar Return görseli render edip paylaşım sheet'i açar.
    @MainActor
    static func shareSolarReturn(personName: String, solarReturn: SolarReturn) {
        let view = SolarReturnShareCard(personName: personName, solarReturn: solarReturn)
        guard let image = renderToImage(view) else { return }
        presentShareSheet(items: [image])
    }

    /// Composite harita görseli render edip paylaşım sheet'i açar.
    @MainActor
    static func shareComposite(person1Name: String, person2Name: String, composite: CompositeChart) {
        let view = CompositeShareCard(person1Name: person1Name, person2Name: person2Name, composite: composite)
        guard let image = renderToImage(view) else { return }
        presentShareSheet(items: [image])
    }

    /// Tarot falı görseli render edip paylaşım sheet'i açar.
    @MainActor
    static func shareTarot(drawnCards: [DrawnCard]) {
        let view = TarotShareCard(drawnCards: drawnCards)
        guard let image = renderToImage(view) else { return }
        presentShareSheet(items: [image])
    }

    // MARK: - Private

    @MainActor
    private static func renderToImage<V: View>(_ view: V) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        renderer.isOpaque = true
        guard let cgImage = renderer.cgImage else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private static func presentShareSheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // iPad popover desteği
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        // En üstteki VC'yi bul
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        topVC.present(activityVC, animated: true)
    }
}
