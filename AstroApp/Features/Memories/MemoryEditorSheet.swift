import SwiftUI

/// Anı ekleme / düzenleme formu
struct MemoryEditorSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let person: BirthData
    /// nil → yeni anı
    let existing: LifeMemory?

    @State private var title = ""
    @State private var emoji = "⭐️"
    @State private var day = Date.now
    @State private var hasTime = false
    @State private var time = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
    @State private var note = ""
    @FocusState private var titleFocused: Bool

    private let emojis = ["⭐️", "❤️", "💍", "🎓", "💼", "🏠", "✈️", "👶", "🎉", "🌱", "🕊️", "🏆"]

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Seçilen gün + saat (bilinmiyorsa öğlen)
    private var combinedDate: Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year, .month, .day], from: day)
        let t = cal.dateComponents([.hour, .minute], from: time)
        var comps = d
        comps.hour = hasTime ? t.hour : 12
        comps.minute = hasTime ? t.minute : 0
        return cal.date(from: comps) ?? day
    }

    private var dateRange: ClosedRange<Date> {
        let upper = Calendar.current.date(byAdding: .year, value: 50, to: .now) ?? .distantFuture
        return min(person.birthDate, upper)...upper
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AstroTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        TextField("", text: $title, prompt: Text("Başlık (ör. Mezuniyetim)").foregroundStyle(AstroTheme.textTertiary))
                            .textFieldStyle(.plain)
                            .focused($titleFocused)
                            .submitLabel(.done)
                            .padding(13)
                            .background(AstroTheme.surface, in: .rect(cornerRadius: 14))
                            .foregroundStyle(.white)

                        emojiPicker

                        VStack(spacing: 12) {
                            DatePicker("Tarih", selection: $day, in: dateRange, displayedComponents: .date)
                            Toggle("Saati biliyorum", isOn: $hasTime.animation())
                                .tint(AstroTheme.accent)
                            if hasTime {
                                DatePicker("Saat", selection: $time, displayedComponents: .hourAndMinute)
                            } else {
                                Text("Saat bilinmiyorsa öğlen kabul edilir; Ay'ın o günkü açıları gösterilmez.")
                                    .font(.caption)
                                    .foregroundStyle(AstroTheme.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(AstroTheme.surface, in: .rect(cornerRadius: 14))

                        TextField("", text: $note, prompt: Text("Not (isteğe bağlı)").foregroundStyle(AstroTheme.textTertiary), axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...6)
                            .padding(13)
                            .background(AstroTheme.surface, in: .rect(cornerRadius: 14))
                            .foregroundStyle(.white)

                        if combinedDate > .now {
                            Label("Planlanan bir gün: yorumlar gelecek zamanla yazılır.", systemImage: "calendar.badge.clock")
                                .font(.caption)
                                .foregroundStyle(AstroTheme.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .environment(\.locale, Locale(identifier: "tr_TR"))
            .navigationTitle(existing == nil ? "Yeni Anı" : "Anıyı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
        .environment(\.colorScheme, .dark)
        .presentationDetents([.large])
    }

    private var emojiPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
            ForEach(emojis, id: \.self) { item in
                Button {
                    emoji = item
                } label: {
                    Text(item)
                        .font(.system(size: 24))
                        .frame(width: 46, height: 46)
                        .background(emoji == item ? AstroTheme.accent.opacity(0.3) : AstroTheme.surface, in: .circle)
                        .overlay { Circle().stroke(emoji == item ? AstroTheme.accent : .clear, lineWidth: 1.5) }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(emoji == item ? .isSelected : [])
            }
        }
    }

    private func load() {
        guard let existing else {
            titleFocused = true
            return
        }
        title = existing.title
        emoji = existing.emoji
        day = existing.date
        hasTime = existing.hasTime
        time = existing.date
        note = existing.note
    }

    private func save() {
        var memory = existing ?? LifeMemory(personID: person.id, title: "", emoji: emoji, date: .now, hasTime: false, note: "")
        memory.title = trimmedTitle
        memory.emoji = emoji
        memory.date = combinedDate
        memory.hasTime = hasTime
        memory.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        appState.memoryStore.save(memory)
        dismiss()
    }
}
