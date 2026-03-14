import SwiftUI

/// Kişi seçimi + manuel giriş bileşeni.
/// Tüm astroloji hesap sayfalarında ortak kullanılır.
struct PersonSelectionCard: View {
    @Environment(AppState.self) private var appState

    // Manuel giriş state'leri
    @State private var useManualEntry = false
    @State private var manualName = ""
    @State private var manualBirthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15, hour: 12))!
    @State private var manualCountryCode = "TR"
    @State private var manualCity = "İstanbul"

    // Kişi seçimi
    @State private var selectedPersonID: UUID?

    let title: String
    let buttonTitle: String
    let buttonIcon: String
    var onCalculate: (BirthData) -> Void

    private var selectedPerson: BirthData? {
        guard let id = selectedPersonID else { return nil }
        return appState.birthDataStore.people.first(where: { $0.id == id })
    }

    private var hasSavedPeople: Bool {
        !appState.birthDataStore.people.isEmpty
    }

    var body: some View {
        VStack(spacing: 14) {
            if hasSavedPeople && !useManualEntry {
                savedPeopleSection
            } else {
                manualEntrySection
            }

            if hasSavedPeople {
                toggleButton
            }

            calculateButton
        }
        .glassCard()
        .onAppear {
            if selectedPersonID == nil {
                selectedPersonID = appState.birthDataStore.ownerPerson?.id
                    ?? appState.birthDataStore.people.first?.id
            }
        }
    }

    // MARK: - Kayıtlı Kişiler

    private var savedPeopleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(AstroTheme.accent)
                Text("Kişi Seçin")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appState.birthDataStore.people) { person in
                        let isSelected = selectedPersonID == person.id
                        Button {
                            selectedPersonID = person.id
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: person.isOwner ? "person.fill" : "person")
                                    .font(.caption)
                                Text(person.name.isEmpty ? "İsimsiz" : person.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(isSelected ? .white : AstroTheme.textSecondary)
                            .frame(width: 72, height: 52)
                            .background(
                                isSelected
                                    ? AnyShapeStyle(AstroTheme.accent.opacity(0.3))
                                    : AnyShapeStyle(AstroTheme.surface),
                                in: .rect(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? AstroTheme.accent.opacity(0.5) : .clear, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Manuel Giriş

    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .foregroundStyle(AstroTheme.accent)
                Text("Bilgileri Girin")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Ad")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                TextField("", text: $manualName, prompt: Text("İsim").foregroundStyle(AstroTheme.textTertiary))
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(AstroTheme.surface, in: .rect(cornerRadius: 10))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Doğum Tarihi ve Saati")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                DatePicker(
                    "",
                    selection: $manualBirthDate,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AstroTheme.accent)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AstroTheme.surface, in: .rect(cornerRadius: 10))
            }

            LocationPickerView(
                selectedCountryCode: $manualCountryCode,
                selectedCity: $manualCity
            )
        }
    }

    // MARK: - Toggle

    private var toggleButton: some View {
        Button {
            useManualEntry.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: useManualEntry ? "person.2" : "keyboard")
                    .font(.caption2)
                Text(useManualEntry ? "Kayıtlı kişilerden seç" : "Manuel giriş yap")
                    .font(.caption)
            }
            .foregroundStyle(AstroTheme.textSecondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(AstroTheme.surface, in: .capsule)
        }
    }

    // MARK: - Hesapla

    private var calculateButton: some View {
        Button {
            if useManualEntry || !hasSavedPeople {
                let coords = WorldCityStore.coordinates(for: manualCity)
                let data = BirthData(
                    name: manualName,
                    birthDate: manualBirthDate,
                    cityName: manualCity,
                    latitude: coords.lat,
                    longitude: coords.lon
                )
                // Manuel girilen kişiyi kaydet
                appState.birthDataStore.addPerson(data)
                onCalculate(data)
            } else if let person = selectedPerson {
                onCalculate(person)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: buttonIcon)
                Text(buttonTitle)
            }
            .glassButton()
        }
        .disabled(!useManualEntry && !hasSavedPeople && manualName.isEmpty)
    }
}
