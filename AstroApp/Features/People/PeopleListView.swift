import SwiftUI

struct PeopleListView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddSheet = false
    @State private var editingPerson: BirthData?

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 12) {
                        if appState.birthDataStore.people.isEmpty {
                            emptyState
                        } else {
                            ForEach(appState.birthDataStore.people) { person in
                                personCard(person)
                            }
                        }

                        addButton
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Kişiler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddSheet) {
                AddPersonSheet()
            }
            .sheet(item: $editingPerson) { person in
                AddPersonSheet(editing: person)
            }
        }
    }

    // MARK: - Person Card

    private func personCard(_ person: BirthData) -> some View {
        let isActive = person.id == appState.birthDataStore.activePersonID

        return Button {
            appState.birthDataStore.setActive(person.id)
            Task { await loadChart(for: person) }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isActive ? AstroTheme.accent.opacity(0.2) : AstroTheme.surface)
                        .frame(width: 44, height: 44)
                    Image(systemName: person.isOwner ? "person.fill" : "person")
                        .font(.title3)
                        .foregroundStyle(isActive ? AstroTheme.accent : AstroTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(person.name.isEmpty ? "İsimsiz" : person.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if person.isOwner {
                            Text("Ben")
                                .font(.caption2.bold())
                                .foregroundStyle(AstroTheme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AstroTheme.accent.opacity(0.15), in: .capsule)
                        }
                    }
                    Text("\(formattedDate(person.birthDate)) · \(person.cityName)")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AstroTheme.accent)
                }
            }
            .padding(14)
            .background(
                isActive
                    ? AnyShapeStyle(AstroTheme.accent.opacity(0.08))
                    : AnyShapeStyle(Color.white.opacity(0.06)),
                in: .rect(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? AstroTheme.accent.opacity(0.3) : AstroTheme.cardBorder, lineWidth: 1)
            )
        }
        .contextMenu {
            Button {
                editingPerson = person
            } label: {
                Label("Düzenle", systemImage: "pencil")
            }

            if !person.isOwner {
                Button(role: .destructive) {
                    appState.birthDataStore.removePerson(person.id)
                } label: {
                    Label("Sil", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button { showAddSheet = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AstroTheme.accent)
                Text("Kişi Ekle")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(AstroTheme.surface, in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AstroTheme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 40))
                .foregroundStyle(AstroTheme.textTertiary)
            Text("Henüz kimse eklenmedi")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Kendinizi ve karşılaştırmak istediğiniz kişileri ekleyin.")
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .glassCard()
    }

    // MARK: - Helpers

    private func loadChart(for person: BirthData) async {
        let chart = await appState.ephemeris.calculateBirthChart(
            date: person.birthDate,
            latitude: person.latitude,
            longitude: person.longitude,
            timeZone: TimeZone(identifier: "Europe/Istanbul")!
        )
        appState.currentChart = chart
        appState.syncWidgetData()
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMM yyyy"
        return f.string(from: date)
    }
}

// MARK: - Add/Edit Person Sheet

struct AddPersonSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let editing: BirthData?

    @State private var name = ""
    @State private var birthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15, hour: 12))!
    @State private var selectedCity = "İstanbul"

    private let cities: [(name: String, lat: Double, lon: Double)] = [
        ("İstanbul", 41.0082, 28.9784),
        ("Ankara", 39.9334, 32.8597),
        ("İzmir", 38.4192, 27.1287),
        ("Antalya", 36.8969, 30.7133),
        ("Bursa", 40.1885, 29.0610),
        ("Adana", 37.0000, 35.3213),
        ("Trabzon", 41.0027, 39.7168),
        ("Diyarbakır", 37.9144, 40.2306),
        ("Konya", 37.8746, 32.4932),
        ("Samsun", 41.2867, 36.3300),
    ]

    init(editing: BirthData? = nil) {
        self.editing = editing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AstroTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("İsim")
                                .font(.caption)
                                .foregroundStyle(AstroTheme.textSecondary)
                            TextField("", text: $name, prompt: Text("İsim").foregroundStyle(AstroTheme.textTertiary))
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Doğum Tarihi ve Saati")
                                .font(.caption)
                                .foregroundStyle(AstroTheme.textSecondary)
                            DatePicker(
                                "",
                                selection: $birthDate,
                                in: ...Date.now,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(AstroTheme.accent)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
                            .colorScheme(.dark)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Doğum Yeri")
                                .font(.caption)
                                .foregroundStyle(AstroTheme.textSecondary)
                            Picker("", selection: $selectedCity) {
                                ForEach(cities, id: \.name) { city in
                                    Text(city.name).tag(city.name)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .tint(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
                        }

                        Button { savePerson() } label: {
                            Text(editing != nil ? "Güncelle" : "Kaydet")
                                .glassButton()
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle(editing != nil ? "Kişi Düzenle" : "Kişi Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
            .onAppear {
                if let person = editing {
                    name = person.name
                    birthDate = person.birthDate
                    selectedCity = person.cityName
                }
            }
        }
    }

    private func savePerson() {
        guard let city = cities.first(where: { $0.name == selectedCity }) else { return }

        if let existing = editing {
            let updated = BirthData(
                id: existing.id,
                name: name,
                birthDate: birthDate,
                cityName: selectedCity,
                latitude: city.lat,
                longitude: city.lon,
                isOwner: existing.isOwner
            )
            appState.birthDataStore.updatePerson(updated)
        } else {
            let person = BirthData(
                name: name,
                birthDate: birthDate,
                cityName: selectedCity,
                latitude: city.lat,
                longitude: city.lon,
                isOwner: false
            )
            appState.birthDataStore.addPerson(person)
        }

        dismiss()
    }
}
