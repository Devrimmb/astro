import SwiftUI

/// Bir anının gökyüzü: iç halka kişinin doğum haritası, dış halka o günün gezegenleri.
/// Altında o tarihte içinde olunan hayat döngüleri ve o günün transit yorumları.
struct MemoryDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    let memoryID: UUID
    let person: BirthData

    @State private var natalChart: BirthChart?
    @State private var report: TransitReport?
    @State private var cycles: [LifeCycleEvent] = []
    @State private var highlightedPlanet: Planet?
    @State private var unlockedByAd = false
    @State private var showEditor = false
    @State private var confirmDelete = false

    private var memory: LifeMemory? { appState.memoryStore.memory(id: memoryID) }

    private var isUnlocked: Bool {
        EntitlementManager.isAdmin
            || entitlements.hasNatalChart
            || appState.chartReadingStore.reading(forPersonID: person.id) != nil
            || unlockedByAd
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()
            if let memory {
                ScrollView {
                    VStack(spacing: 16) {
                        header(memory)
                        wheelCard
                        if !cycles.isEmpty { cyclesCard(memory) }
                        transitsCard(memory)
                        if !memory.note.isEmpty { noteCard(memory.note) }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Anı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Düzenle", systemImage: "pencil") { showEditor = true }
                    Button("Sil", systemImage: "trash", role: .destructive) { confirmDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AstroTheme.accent)
                }
                .accessibilityLabel("Anı seçenekleri")
            }
        }
        .sheet(isPresented: $showEditor) {
            MemoryEditorSheet(person: person, existing: memory)
        }
        .alert("Anı silinsin mi?", isPresented: $confirmDelete) {
            Button("Sil", role: .destructive) {
                appState.memoryStore.remove(id: memoryID)
                dismiss()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("\"\(memory?.title ?? "")\" kalıcı olarak silinecek.")
        }
        // Tarih değişince (düzenleme) gökyüzü yeniden hesaplanır
        .task(id: memory?.date) { await load() }
    }

    // MARK: - Başlık

    private func header(_ memory: LifeMemory) -> some View {
        VStack(spacing: 8) {
            Text(memory.emoji)
                .font(.system(size: 44))
                .frame(width: 80, height: 80)
                .background(AstroTheme.accent.opacity(0.15), in: .circle)
            Text(memory.title)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("\(MemoryText.dateText(memory)) · \(MemoryText.ageText(memory, birthDate: person.birthDate))")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
            Text(MemoryText.relativeText(memory))
                .font(.caption.weight(.semibold))
                .foregroundStyle(memory.isFuture ? AstroTheme.accent : AstroTheme.textTertiary)
        }
        .padding(.top, 12)
    }

    // MARK: - Çark

    @ViewBuilder
    private var wheelCard: some View {
        if let natalChart, let report {
            VStack(spacing: 8) {
                TransitBiWheelView(
                    natalChart: natalChart,
                    transitPositions: report.transitPositions,
                    size: 340,
                    highlightedPlanet: highlightedPlanet
                ) { planet in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        highlightedPlanet = highlightedPlanet == planet ? nil : planet
                    }
                }
                HStack(spacing: 14) {
                    legend(color: .white, text: "İç: doğum haritan")
                    legend(color: AstroTheme.accentSecondary, text: "Dış: o günün gökyüzü")
                }
                Text(highlightedPlanet.map { "\($0.glyph) \($0.name) · o gün ona gelen açılar parlıyor" }
                     ?? "Doğum haritandaki bir gezegene dokun")
                    .font(.caption2)
                    .foregroundStyle(highlightedPlanet.map { AstroTheme.planet($0) } ?? AstroTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .glassCard()
        } else {
            ProgressView()
                .tint(AstroTheme.accent)
                .frame(height: 340)
        }
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)
        }
    }

    // MARK: - Döngüler

    private func cyclesCard(_ memory: LifeMemory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(memory.isFuture ? "O tarihte içinde olacağın dönemeç" : "O tarihte içindeydin")
                .font(.headline)
                .foregroundStyle(.white)
            ForEach(cycles) { event in
                HStack(spacing: 10) {
                    Text(event.kind.planet.glyph)
                        .font(.system(size: 18, design: .serif))
                        .foregroundStyle(AstroTheme.planet(event.kind.planet))
                        .frame(width: 34, height: 34)
                        .background(AstroTheme.planet(event.kind.planet).opacity(0.15), in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LifeCycleTiming.title(event))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        if let summary = LifeCycleInterpretation.entry(for: event.kind)?.summary {
                            Text(summary)
                                .font(.caption)
                                .foregroundStyle(AstroTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Transitler

    /// Majör açılar, dar orb önce; saat bilinmiyorsa Ay'ınkiler çıkarılır (gün içinde ~13° kayar)
    private func transitItems(_ memory: LifeMemory) -> [DailyCosmicCoach.GuidanceItem] {
        guard let report else { return [] }
        return report.aspects
            .filter { $0.type.isMajor && (memory.hasTime || $0.transitPlanet != .moon) }
            .sorted { $0.orb < $1.orb }
            .prefix(8)
            .map { DailyCosmicCoach.memoryInterpretation($0, isPast: !memory.isFuture) }
    }

    @ViewBuilder
    private func transitsCard(_ memory: LifeMemory) -> some View {
        if report != nil {
            let items = transitItems(memory)
            VStack(alignment: .leading, spacing: 12) {
                Text(memory.isFuture ? "O gün gökyüzü sana ne diyecek" : "O gün gökyüzü sana ne diyordu")
                    .font(.headline)
                    .foregroundStyle(.white)
                if items.isEmpty {
                    Text("O gün doğum haritana belirgin bir açı yapan transit yok.")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textSecondary)
                } else if isUnlocked {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(item.message)
                                .font(.subheadline)
                                .foregroundStyle(AstroTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    AdGateView(
                        title: "Yorumları Aç",
                        description: "O günün gökyüzü yorumlarını görmek için kısa bir reklam izle. Doğum haritası açılmış kişilerde yorumlar ücretsizdir."
                    ) {
                        unlockedByAd = true
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
    }

    private func noteCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Not")
                .font(.headline)
                .foregroundStyle(.white)
            Text(note)
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Hesap

    private func load() async {
        guard let memory else { return }
        let chart: BirthChart
        if let natalChart {
            chart = natalChart
        } else {
            chart = await LifeCycleCache.natalChart(for: person, appState: appState)
            natalChart = chart
        }
        let date = memory.date
        report = await Task.detached(priority: .userInitiated) {
            TransitCalculator.calculate(natalChart: chart, transitDate: date)
        }.value
        let events = await LifeCycleCache.events(for: chart)
        cycles = events.filter { LifeCycleTiming.isActive($0, now: date) }
    }
}
