import SwiftUI

/// Kozmik kimlik: tam ekran, sayfa sayfa ilerleyen hikâye. Sağa dokun → sonraki,
/// sola dokun → önceki; her sayfa tek tek ya da hepsi birden görsel olarak paylaşılır.
struct CosmicIdentityStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var identity: CosmicIdentity
    @State private var index = 0
    @State private var revealed = false
    @State private var progress: Double = 0

    private let pageDuration: Double = 6

    init(chart: BirthChart, name: String, cityName: String? = nil) {
        _identity = State(initialValue: CosmicIdentity(name: name, chart: chart, cityName: cityName))
    }

    private var pages: [CosmicIdentityPage] { identity.pages }
    private var page: CosmicIdentityPage { pages[min(index, pages.count - 1)] }

    var body: some View {
        GeometryReader { geo in
            let controlsHeight: CGFloat = 140
            let scale = min(geo.size.width / 1080, (geo.size.height - controlsHeight) / 1920)

            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        progressBars
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(.white.opacity(0.15), in: .circle)
                        }
                        .accessibilityLabel("Kapat")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    CosmicIdentityPageView(page: page, identity: identity, revealed: revealed)
                        .frame(width: 1080, height: 1920)
                        .scaleEffect(scale)
                        .frame(width: 1080 * scale, height: 1920 * scale)
                        .clipShape(.rect(cornerRadius: 22))
                        .overlay { tapZones }
                        .id(page)
                        .transition(.opacity)
                        .accessibilityElement(children: .combine)
                        .accessibilityAction(named: "Sonraki sayfa") { next() }
                        .accessibilityAction(named: "Önceki sayfa") { previous() }

                    HStack(spacing: 12) {
                        Button {
                            ShareImageRenderer.shareCosmicIdentity(identity, pages: [page])
                        } label: {
                            Label("Bu sayfayı paylaş", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .glassButton()
                        }
                        Button {
                            ShareImageRenderer.shareCosmicIdentity(identity, pages: pages)
                        } label: {
                            Label("Tümü", systemImage: "square.stack")
                                .glassButton()
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
        .task {
            let events = await LifeCycleCache.events(for: identity.chart)
            identity.nextCycle = LifeCycleTiming.highlight(events)
        }
        .task(id: index) { await playPage() }
    }

    // MARK: - İlerleme

    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(Array(pages.enumerated()), id: \.offset) { i, _ in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.25))
                        Capsule().fill(.white)
                            .frame(width: geo.size.width * fill(for: i))
                    }
                }
                .frame(height: 3)
            }
        }
    }

    private func fill(for i: Int) -> CGFloat {
        if i < index { return 1 }
        if i > index { return 0 }
        return reduceMotion ? 1 : CGFloat(progress)
    }

    private var tapZones: some View {
        HStack(spacing: 0) {
            Color.clear.contentShape(.rect).onTapGesture { previous() }
            Color.clear.contentShape(.rect).onTapGesture { next() }
        }
    }

    /// Sayfa açılınca öğeleri sırayla gösterir; süre dolunca (son sayfa hariç) ilerler
    private func playPage() async {
        progress = 0
        revealed = false
        if reduceMotion {
            revealed = true
            return
        }
        try? await Task.sleep(for: .milliseconds(80))
        revealed = true
        let tick = 0.05
        while progress < 1 {
            try? await Task.sleep(for: .seconds(tick))
            if Task.isCancelled { return }
            progress = min(1, progress + tick / pageDuration)
        }
        if index < pages.count - 1 { next() }
    }

    private func next() {
        guard index < pages.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) { index += 1 }
    }

    private func previous() {
        guard index > 0 else {
            Task { await playPage() }
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) { index -= 1 }
    }
}
