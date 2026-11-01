import SwiftUI

/// Anı haritası: kişinin önemli günleri (geçmiş ve planlanan). Her anıda o günün gökyüzü
/// kişinin haritası etrafında gösterilir.
struct MemoryMapView: View {
    @Environment(AppState.self) private var appState

    /// Verilirse kişi seçimi atlanır
    var initialPerson: BirthData? = nil

    @State private var person: BirthData?
    @State private var showEditor = false
    @State private var memoryToDelete: LifeMemory?

    private var memories: [LifeMemory] {
        guard let person else { return [] }
        return appState.memoryStore.memories(for: person.id)
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()
            if let person {
                content(person: person)
            } else {
                personSelectionView
            }
        }
        .navigationTitle("Anı Haritası")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if person != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kişi değiştir") { person = nil }
                        .foregroundStyle(AstroTheme.accent)
                }
            }
        }
        .onAppear {
            if person == nil, let initialPerson { person = initialPerson }
        }
        .sheet(isPresented: $showEditor) {
            if let person {
                MemoryEditorSheet(person: person, existing: nil)
            }
        }
        .alert(
            "Anı silinsin mi?",
            isPresented: Binding(get: { memoryToDelete != nil }, set: { if !$0 { memoryToDelete = nil } }),
            presenting: memoryToDelete
        ) { memory in
            Button("Sil", role: .destructive) { appState.memoryStore.remove(id: memory.id) }
            Button("Vazgeç", role: .cancel) {}
        } message: { memory in
            Text("\"\(memory.title)\" kalıcı olarak silinecek.")
        }
    }

    // MARK: - Kişi seçimi

    private var personSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Anı Haritası")
                        .font(.largeTitle)
                        .fontDesign(.serif)
                        .foregroundStyle(.white)
                    Text("Önemli günlerini kaydet, o günün gökyüzünü haritanın etrafında gör")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                PersonSelectionCard(
                    title: "Kişi Seçin",
                    buttonTitle: "Anılara Git",
                    buttonIcon: "clock.arrow.circlepath"
                ) { data in
                    person = data
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Liste

    private func content(person: BirthData) -> some View {
        let upcoming = memories.filter(\.isFuture)
        let past = memories.filter { !$0.isFuture }.reversed()

        return ScrollView {
            VStack(spacing: 16) {
                Button {
                    showEditor = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Anı ekle")
                    }
                    .frame(maxWidth: .infinity)
                    .glassButton()
                }

                if memories.isEmpty {
                    emptyState
                }
                if !upcoming.isEmpty {
                    section(title: "Yaklaşan günler", memories: upcoming, person: person)
                }
                if !past.isEmpty {
                    section(title: "Anılar", memories: Array(past), person: person)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("✨")
                .font(.system(size: 44))
            Text("Henüz anı yok")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Mezuniyet, ilk iş, bir tanışma ya da planladığın bir gün… Kaydet; o günün gökyüzünü haritanın etrafında görelim.")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard()
    }

    private func section(title: String, memories: [LifeMemory], person: BirthData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            VStack(spacing: 0) {
                ForEach(Array(memories.enumerated()), id: \.element.id) { index, memory in
                    NavigationLink {
                        MemoryDetailView(memoryID: memory.id, person: person)
                    } label: {
                        MemoryRow(memory: memory, birthDate: person.birthDate)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Sil", systemImage: "trash", role: .destructive) { memoryToDelete = memory }
                    }
                    if index < memories.count - 1 {
                        Divider().overlay(AstroTheme.cardBorder)
                    }
                }
            }
        }
        .glassCard()
    }
}

// MARK: - Satır

/// Anı satırı; Anı Haritası ve Hayat Döngüleri zaman çizgisi ortak kullanır
struct MemoryRow: View {
    let memory: LifeMemory
    let birthDate: Date

    var body: some View {
        HStack(spacing: 12) {
            Text(memory.emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(AstroTheme.accent.opacity(0.14), in: .circle)
            VStack(alignment: .leading, spacing: 3) {
                Text(memory.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(MemoryText.dateText(memory))
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(MemoryText.ageText(memory, birthDate: birthDate))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(AstroTheme.textSecondary)
                Text(MemoryText.relativeText(memory))
                    .font(.caption2)
                    .foregroundStyle(memory.isFuture ? AstroTheme.accent : AstroTheme.textTertiary)
            }
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .padding(.vertical, 10)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

enum MemoryText {
    static func dateText(_ memory: LifeMemory) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = memory.hasTime ? "d MMMM yyyy · HH:mm" : "d MMMM yyyy"
        return f.string(from: memory.date)
    }

    static func ageText(_ memory: LifeMemory, birthDate: Date) -> String {
        let years = Calendar.current.dateComponents([.year], from: birthDate, to: memory.date).year ?? 0
        return "\(max(0, years)) yaş"
    }

    /// "3 yıl önce", "bugün", "12 gün sonra"
    static func relativeText(_ memory: LifeMemory, now: Date = .now) -> String {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month, .day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: memory.date))
        let y = abs(c.year ?? 0), m = abs(c.month ?? 0), d = abs(c.day ?? 0)
        let suffix = memory.date > now ? "sonra" : "önce"
        if y > 0 { return "\(y) yıl \(suffix)" }
        if m > 0 { return "\(m) ay \(suffix)" }
        if d > 0 { return "\(d) gün \(suffix)" }
        return "bugün"
    }
}
