import SwiftUI

/// Hayat döngüleri: Satürn/Jüpiter dönüşleri, Uranüs karşıtlığı gibi büyük dönemeçler
/// tek zaman çizgisinde. Liste serbest; ayrıntılı yorum, kişinin ödenmiş harita okuması
/// yoksa ödüllü reklamla açılır.
struct LifeCyclesView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements

    /// Verilirse kişi seçimi atlanır (anasayfa kartından gelişte)
    var initialPerson: BirthData? = nil

    @State private var person: BirthData?
    @State private var events: [LifeCycleEvent]?
    @State private var selected: LifeCycleEvent?
    @State private var unlockedByAd: Set<String> = []
    @State private var showPast = false

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            if person == nil {
                personSelectionView
            } else if let events, let person {
                content(events: events, person: person)
            } else {
                VStack(spacing: 12) {
                    ProgressView().tint(AstroTheme.accent)
                    Text("Döngüler hesaplanıyor…")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
        }
        .navigationTitle("Hayat Döngüleri")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if person != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kişi değiştir") {
                        person = nil
                        events = nil
                    }
                    .foregroundStyle(AstroTheme.accent)
                }
            }
        }
        .task {
            if let initialPerson, person == nil {
                await load(initialPerson)
            }
        }
        .sheet(item: $selected) { event in
            if let person {
                LifeCycleDetailSheet(
                    event: event,
                    person: person,
                    isUnlocked: isUnlocked(event, for: person),
                    onUnlock: { unlockedByAd.insert(event.id) }
                )
            }
        }
    }

    // MARK: - Kişi seçimi

    private var personSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Hayat Döngüleri")
                        .font(.largeTitle)
                        .fontDesign(.serif)
                        .foregroundStyle(.white)
                    Text("Satürn dönüşü, Jüpiter dönüşleri ve hayatının büyük dönemeçleri")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                PersonSelectionCard(
                    title: "Kişi Seçin",
                    buttonTitle: "Döngüleri Hesapla",
                    buttonIcon: "hourglass"
                ) { data in
                    Task { await load(data) }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    // MARK: - İçerik

    private func content(events: [LifeCycleEvent], person: BirthData) -> some View {
        let now = Date.now
        let active = events.filter { LifeCycleTiming.isActive($0, now: now) }
        // Döngüler ve kişinin anıları aynı zaman çizgisinde
        let memories = appState.memoryStore.memories(for: person.id)
        let upcoming = (events.filter { $0.start > now && !LifeCycleTiming.isActive($0, now: now) }.map(TimelineItem.cycle)
            + memories.filter(\.isFuture).map(TimelineItem.memory))
            .sorted { $0.date < $1.date }
        let past = (events.filter { $0.end < now && !LifeCycleTiming.isActive($0, now: now) }.map(TimelineItem.cycle)
            + memories.filter { !$0.isFuture }.map(TimelineItem.memory))
            .sorted { $0.date > $1.date }

        return ScrollView {
            VStack(spacing: 16) {
                heroCard(active: active.first, next: events.first { $0.start > now }, person: person)

                if !active.isEmpty {
                    section(title: "Şu an içindesin", items: active.map(TimelineItem.cycle), person: person, now: now)
                }
                if !upcoming.isEmpty {
                    section(title: "Yaklaşan", items: upcoming, person: person, now: now)
                }
                if !past.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { showPast.toggle() }
                        } label: {
                            HStack {
                                Text("Geçmiş dönemeçler (\(past.count))")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: showPast ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(AstroTheme.textTertiary)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        if showPast {
                            timeline(past, person: person, now: now)
                        }
                    }
                    .glassCard()
                }

                Text("Tarihler gezegenin doğum konumuna tam açı yaptığı anlardır; retro hareket nedeniyle bir dönemde birden fazla tarih olabilir.")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    /// Öne çıkan kart: içinde bulunulan dönem, yoksa sıradaki dönemeç + geri sayım
    @ViewBuilder
    private func heroCard(active: LifeCycleEvent?, next: LifeCycleEvent?, person: BirthData) -> some View {
        if let event = active ?? next {
            let color = AstroTheme.planet(event.kind.planet)
            Button {
                selected = event
            } label: {
                VStack(spacing: 10) {
                    Text(active != nil ? "ŞU AN İÇİNDESİN" : "SIRADAKİ BÜYÜK DÖNEMEÇ")
                        .font(.caption2.weight(.bold))
                        .kerning(1.2)
                        .foregroundStyle(AstroTheme.textTertiary)
                    Text(event.kind.planet.glyph)
                        .font(.system(size: 40, design: .serif))
                        .foregroundStyle(color)
                        .frame(width: 76, height: 76)
                        .background(color.opacity(0.15), in: .circle)
                        .shadow(color: color.opacity(0.4), radius: 16)
                    Text(LifeCycleTiming.title(event))
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if active == nil {
                        Text(LifeCycleTiming.countdown(to: event.start))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(color)
                    }
                    Text(LifeCycleTiming.dateRange(event) + " · " + LifeCycleTiming.ageText(event, birthDate: person.birthDate))
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                    if let summary = LifeCycleInterpretation.entry(for: event.kind)?.summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                    Text("Yorumu gör")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AstroTheme.accent)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .glassCard()
            }
            .buttonStyle(.plain)
        }
    }

    private func section(title: String, items: [TimelineItem], person: BirthData, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            timeline(items, person: person, now: now)
        }
        .glassCard()
    }

    private func timeline(_ items: [TimelineItem], person: BirthData, now: Date) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                switch item {
                case .cycle(let event):
                    row(event, person: person, now: now)
                case .memory(let memory):
                    NavigationLink {
                        MemoryDetailView(memoryID: memory.id, person: person)
                    } label: {
                        MemoryRow(memory: memory, birthDate: person.birthDate)
                    }
                    .buttonStyle(.plain)
                }
                if index < items.count - 1 {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
    }

    private func row(_ event: LifeCycleEvent, person: BirthData, now: Date) -> some View {
        let color = AstroTheme.planet(event.kind.planet)
        let isPast = event.end < now && !LifeCycleTiming.isActive(event, now: now)
        return Button {
            selected = event
        } label: {
            HStack(spacing: 12) {
                Text(event.kind.planet.glyph)
                    .font(.system(size: 20, design: .serif))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.14), in: .circle)
                VStack(alignment: .leading, spacing: 3) {
                    Text(LifeCycleTiming.title(event))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(LifeCycleTiming.dateRange(event))
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(LifeCycleTiming.ageText(event, birthDate: person.birthDate))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(AstroTheme.textSecondary)
                    if event.start > now {
                        Text(LifeCycleTiming.countdown(to: event.start))
                            .font(.caption2)
                            .foregroundStyle(color)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            .padding(.vertical, 10)
            .opacity(isPast ? 0.6 : 1)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Mantık

    /// Kişinin ödenmiş harita okuması varsa (ya da eski tek seferlik ürün / admin) yorum açıktır
    private func isUnlocked(_ event: LifeCycleEvent, for person: BirthData) -> Bool {
        EntitlementManager.isAdmin
            || entitlements.hasNatalChart
            || appState.chartReadingStore.reading(forPersonID: person.id) != nil
            || unlockedByAd.contains(event.id)
    }

    private func load(_ data: BirthData) async {
        person = data
        events = nil
        showPast = false
        let result = await LifeCycleCache.events(for: data, appState: appState)
        guard person == data else { return }
        events = result
    }
}

// MARK: - Zaman çizgisi öğesi

/// Hayat Döngüleri zaman çizgisinde bir döngü ya da kişinin bir anısı
private enum TimelineItem: Identifiable {
    case cycle(LifeCycleEvent)
    case memory(LifeMemory)

    var id: String {
        switch self {
        case .cycle(let e): "cycle_\(e.id)"
        case .memory(let m): "memory_\(m.id)"
        }
    }

    var date: Date {
        switch self {
        case .cycle(let e): e.start
        case .memory(let m): m.date
        }
    }
}

// MARK: - Zaman metinleri

enum LifeCycleTiming {
    /// Öne çıkacak dönemeç: içinde bulunulan, yoksa sıradaki
    static func highlight(_ events: [LifeCycleEvent], now: Date = .now) -> (event: LifeCycleEvent, isActive: Bool)? {
        if let active = events.first(where: { isActive($0, now: now) }) { return (active, true) }
        if let next = events.first(where: { $0.start > now }) { return (next, false) }
        return nil
    }

    /// Tam açıdan ~2 ay önce başlayıp son tam açıdan ~2 ay sonra biten dönem "içinde" sayılır
    static func isActive(_ event: LifeCycleEvent, now: Date) -> Bool {
        let margin: TimeInterval = 60 * 86_400
        return now >= event.start.addingTimeInterval(-margin) && now <= event.end.addingTimeInterval(margin)
    }

    static func title(_ event: LifeCycleEvent) -> String {
        let base = LifeCycleInterpretation.entry(for: event.kind)?.title ?? event.kind.rawValue
        return event.kind.isRecurring ? "\(event.occurrence). \(base)" : base
    }

    /// full: ay adı tam ("Ekim 2029"); değilse kısa ("Eki 2029")
    static func dateRange(_ event: LifeCycleEvent, full: Bool = false) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = full ? "MMMM yyyy" : "MMM yyyy"
        let a = f.string(from: event.start)
        let b = f.string(from: event.end)
        return a == b ? a : "\(a) – \(b)"
    }

    static func ageText(_ event: LifeCycleEvent, birthDate: Date) -> String {
        let years = Calendar.current.dateComponents([.year], from: birthDate, to: event.start).year ?? 0
        return "\(years) yaş"
    }

    /// "2 yıl 4 ay sonra", "5 ay sonra", "12 gün sonra"
    static func countdown(to date: Date, from now: Date = .now) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: now, to: date)
        let y = c.year ?? 0, m = c.month ?? 0, d = c.day ?? 0
        if y > 0 { return m > 0 ? "\(y) yıl \(m) ay sonra" : "\(y) yıl sonra" }
        if m > 0 { return "\(m) ay sonra" }
        return d > 0 ? "\(d) gün sonra" : "çok yakında"
    }
}

// MARK: - Ayrıntı sheet'i

private struct LifeCycleDetailSheet: View {
    let event: LifeCycleEvent
    let person: BirthData
    let isUnlocked: Bool
    var onUnlock: () -> Void

    private var entry: LifeCycleEntry? { LifeCycleInterpretation.entry(for: event.kind) }
    private var color: Color { AstroTheme.planet(event.kind.planet) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                datesCard
                if isUnlocked {
                    readingCard
                } else {
                    AdGateView(
                        title: "Yorumu Aç",
                        description: "Bu döngünün ayrıntılı yorumunu görmek için kısa bir reklam izle. Doğum haritası açılmış kişilerde yorumlar ücretsizdir."
                    ) {
                        onUnlock()
                    }
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
        .astroSheetStyle()
    }

    private var header: some View {
        HStack(spacing: 14) {
            Text(event.kind.planet.glyph)
                .font(.system(size: 30, design: .serif))
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.15), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(LifeCycleTiming.title(event))
                    .font(.title2)
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                if let entry {
                    Text("\(entry.planet) · \(entry.aspect)")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private var datesCard: some View {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy"
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.hits.count > 1 ? "Tam açı tarihleri" : "Tam açı tarihi")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(LifeCycleTiming.ageText(event, birthDate: person.birthDate))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            ForEach(event.hits, id: \.self) { hit in
                HStack(spacing: 8) {
                    Circle().fill(color).frame(width: 6, height: 6)
                    Text(f.string(from: hit))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
            if event.start > .now {
                Text(LifeCycleTiming.countdown(to: event.start))
                    .font(.caption)
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    @ViewBuilder
    private var readingCard: some View {
        if let entry {
            VStack(alignment: .leading, spacing: 10) {
                Text(entry.summary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                if let note = entry.occurrences?[String(event.occurrence)] {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(color)
                }
                MarkdownTextView(entry.description)
                Text("Tipik yaşlar: \(entry.typicalAges)")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
    }
}
