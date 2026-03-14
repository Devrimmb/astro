import SwiftUI

/// Ülke ve şehir seçici bileşen — aranabilir, Türkiye default.
struct LocationPickerView: View {
    @Binding var selectedCountryCode: String
    @Binding var selectedCity: String

    @State private var showCountryPicker = false
    @State private var showCityPicker = false

    private var countryName: String {
        WorldCityStore.countries.first(where: { $0.code == selectedCountryCode })?.name ?? "Türkiye"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ülke seçimi
            Text("Ülke")
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)

            Button {
                showCountryPicker = true
            } label: {
                HStack {
                    Text(countryName)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .padding(12)
                .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
            }

            // Şehir seçimi
            Text("Şehir")
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)

            Button {
                showCityPicker = true
            } label: {
                HStack {
                    Text(selectedCity)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .padding(12)
                .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountrySearchSheet(selectedCode: $selectedCountryCode) {
                // Ülke değişince şehiri o ülkenin ilk şehrine ayarla
                let cities = WorldCityStore.cities(for: selectedCountryCode)
                selectedCity = cities.first?.city ?? "İstanbul"
            }
        }
        .sheet(isPresented: $showCityPicker) {
            CitySearchSheet(countryCode: selectedCountryCode, selectedCity: $selectedCity)
        }
    }
}

// MARK: - Ülke Arama Sheet

private struct CountrySearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCode: String
    var onSelect: () -> Void

    @State private var search = ""

    private var filtered: [(name: String, code: String)] {
        if search.isEmpty { return WorldCityStore.countries }
        let query = search.lowercased()
        return WorldCityStore.countries.filter {
            $0.name.lowercased().contains(query) || $0.code.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AstroTheme.background.ignoresSafeArea()

                List(filtered, id: \.code) { country in
                    Button {
                        selectedCode = country.code
                        onSelect()
                        dismiss()
                    } label: {
                        HStack {
                            Text(country.name)
                                .foregroundStyle(.white)
                            Spacer()
                            if selectedCode == country.code {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AstroTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(AstroTheme.surface)
                }
                .listStyle(.plain)
                .searchable(text: $search, prompt: "Ülke ara...")
            }
            .navigationTitle("Ülke Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Şehir Arama Sheet

private struct CitySearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    let countryCode: String
    @Binding var selectedCity: String

    @State private var search = ""

    private var cities: [WorldCity] {
        let all = WorldCityStore.cities(for: countryCode)
        if search.isEmpty { return all }
        let query = search.lowercased()
        return all.filter { $0.city.lowercased().contains(query) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AstroTheme.background.ignoresSafeArea()

                List(cities) { city in
                    Button {
                        selectedCity = city.city
                        dismiss()
                    } label: {
                        HStack {
                            Text(city.city)
                                .foregroundStyle(.white)
                            Spacer()
                            if selectedCity == city.city {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AstroTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(AstroTheme.surface)
                }
                .listStyle(.plain)
                .searchable(text: $search, prompt: "Şehir ara...")
            }
            .navigationTitle("Şehir Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
    }
}
