import SwiftUI

/// Yeni kişi girişi — tekerlek seçiciler; tarih/saat/şehir değiştikçe Büyük Üçlü
/// canlı hesaplanır ve arkadaki çark aynı haritaya yaylanır (`onPreview`).
struct ManualBirthEntrySheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    /// Her yeni önizleme haritasında çağrılır (arkadaki çark için)
    var onPreview: (BirthChart) -> Void
    /// "Kaydet ve hesapla" — kişi + hesaplanmış harita
    var onSave: (BirthData, BirthChart) -> Void

    @State private var name = ""
    @State private var day = 15
    @State private var month = 6
    @State private var year = 1995
    @State private var hour = 14
    @State private var minute = 30
    @State private var countryCode = "TR"
    @State private var city = "İstanbul"

    @State private var preview: BirthChart?
    @State private var lastSigns: [ZodiacSign?] = [nil, nil, nil]
    @State private var pulses = [0, 0, 0]
    @State private var computeTask: Task<Void, Never>?
    @FocusState private var nameFocused: Bool

    private let pulseHaptic = UIImpactFeedbackGenerator(style: .light)
    private let months = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
                          "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
    private var years: [Int] { Array(1930...Calendar.current.component(.year, from: .now)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("Yeni kişi")
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AstroTheme.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(AstroTheme.surface, in: .circle)
                    }
                    .accessibilityLabel("Kapat")
                }
                .padding(.top, 6)

                liveBigThree

                Text("Tarihi ve saati çevir, harita canlı hesaplansın")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textTertiary)

                TextField("", text: $name, prompt: Text("İsim").foregroundStyle(AstroTheme.textTertiary))
                    .textFieldStyle(.plain)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .padding(13)
                    .background(AstroTheme.surface, in: .rect(cornerRadius: 14))
                    .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AstroTheme.cardBorder, lineWidth: 1) }
                    .foregroundStyle(.white)

                pickers

                LocationPickerView(selectedCountryCode: $countryCode, selectedCity: $city)

                Button {
                    save()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                        Text("Kaydet ve hesapla")
                    }
                    .frame(maxWidth: .infinity)
                    .glassButton()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || preview == nil)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .environment(\.colorScheme, .dark)
        .onAppear { recompute(immediate: true) }
        .onChange(of: [day, month, year, hour, minute]) { _, _ in recompute() }
        .onChange(of: city) { _, _ in recompute() }
        .onChange(of: countryCode) { _, _ in recompute() }
        .onDisappear { computeTask?.cancel() }
    }

    // MARK: - Canlı Büyük Üçlü

    private var liveBigThree: some View {
        HStack(spacing: 8) {
            LiveSignCard(label: "Güneş", longitude: preview?.planets.first(where: { $0.planet == .sun })?.longitude, pulse: pulses[0])
            LiveSignCard(label: "Ay", longitude: preview?.planets.first(where: { $0.planet == .moon })?.longitude, pulse: pulses[1])
            LiveSignCard(label: "Yükselen", longitude: preview?.houses.first(where: { $0.id == 1 })?.cusp, pulse: pulses[2])
        }
    }

    // MARK: - Tekerlekler

    private var pickers: some View {
        GeometryReader { geo in
            let unit = (geo.size.width - 14) / 4.6
            let widths: [CGFloat] = [unit * 0.75, unit * 1.35, unit * 1.0, 14, unit * 0.75, unit * 0.75]
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    ForEach(Array(["Gün", "Ay", "Yıl", "", "Saat", "Dk"].enumerated()), id: \.offset) { i, title in
                        Text(title)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .frame(width: widths[i])
                    }
                }
                HStack(spacing: 0) {
                    wheel(selection: $day, values: Array(1...31), width: widths[0]) { "\($0)" }
                    wheel(selection: $month, values: Array(1...12), width: widths[1]) { months[$0 - 1] }
                    wheel(selection: $year, values: years, width: widths[2]) { "\($0)" }
                    Text(":")
                        .font(.headline)
                        .foregroundStyle(AstroTheme.textTertiary)
                        .frame(width: widths[3])
                    wheel(selection: $hour, values: Array(0...23), width: widths[4]) { String(format: "%02d", $0) }
                    wheel(selection: $minute, values: Array(0...59), width: widths[5]) { String(format: "%02d", $0) }
                }
                .background(alignment: .center) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AstroTheme.accent.opacity(0.14))
                        .overlay { RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(AstroTheme.accent.opacity(0.3), lineWidth: 1) }
                        .frame(height: 34)
                }
            }
        }
        .frame(height: 140)
        .padding(.top, 4)
    }

    private func wheel(selection: Binding<Int>, values: [Int], width: CGFloat, label: @escaping (Int) -> String) -> some View {
        Picker("", selection: selection) {
            ForEach(values, id: \.self) { v in
                Text(label(v))
                    .font(.system(size: 16, weight: v == selection.wrappedValue ? .semibold : .regular))
                    .foregroundStyle(v == selection.wrappedValue ? .white : AstroTheme.textSecondary)
                    .tag(v)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(width: width, height: 120)
        .clipped()
        .compositingGroup()
    }

    // MARK: - Hesap

    private var birthDate: Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        let maxDay = Calendar.current.range(of: .day, in: .month,
                                            for: Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? .now)?.count ?? 31
        comps.day = min(day, maxDay)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? .now
    }

    private func recompute(immediate: Bool = false) {
        computeTask?.cancel()
        let date = birthDate
        let coords = WorldCityStore.coordinates(for: city, countryCode: countryCode)
        computeTask = Task {
            if !immediate {
                try? await Task.sleep(for: .milliseconds(150))
                if Task.isCancelled { return }
            }
            let tz = TimeZone(identifier: coords.tz) ?? .current
            let chart = await appState.ephemeris.calculateBirthChart(
                date: date, latitude: coords.lat, longitude: coords.lon, timeZone: tz)
            if Task.isCancelled { return }
            apply(chart)
        }
    }

    private func apply(_ chart: BirthChart) {
        let signs: [ZodiacSign?] = [chart.sunSign, chart.moonSign, chart.ascendant]
        var changed = false
        for i in 0..<3 where lastSigns[i] != nil && lastSigns[i] != signs[i] {
            pulses[i] += 1
            changed = true
        }
        if changed { pulseHaptic.impactOccurred(intensity: 0.7) }
        lastSigns = signs
        preview = chart
        onPreview(chart)
    }

    private func save() {
        guard let preview else { return }
        let coords = WorldCityStore.coordinates(for: city, countryCode: countryCode)
        let data = BirthData(
            name: name.trimmingCharacters(in: .whitespaces),
            birthDate: birthDate,
            cityName: city,
            latitude: coords.lat,
            longitude: coords.lon
        )
        onSave(data, preview)
    }
}

// MARK: - Canlı burç kartı

/// Güneş / Ay / Yükselen kartı — burç değişince altın halka nabız atar
private struct LiveSignCard: View {
    let label: String
    let longitude: Double?
    let pulse: Int

    @State private var ringScale: CGFloat = 1
    @State private var ringOpacity = 0.0

    private var sign: ZodiacSign? { longitude.map { ZodiacSign.from(longitude: $0) } }

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AstroTheme.textSecondary)
            Text(sign?.name ?? "—")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(sign.map { AstroTheme.element($0.element) } ?? .white)
                .contentTransition(.numericText())
            Text(longitude.map(Self.degreeText) ?? " ")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AstroTheme.surface, in: .rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AstroTheme.cardBorder, lineWidth: 1) }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AstroTheme.gold, lineWidth: 1.5)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .allowsHitTesting(false)
        }
        .animation(.easeInOut(duration: 0.2), value: sign)
        .onChange(of: pulse) { _, _ in
            ringScale = 1
            ringOpacity = 0.9
            withAnimation(.easeOut(duration: 0.7)) {
                ringScale = 1.22
                ringOpacity = 0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(sign?.name ?? "bilinmiyor")")
    }

    static func degreeText(_ longitude: Double) -> String {
        let inSign = LiveChartWheelModel.norm(longitude).truncatingRemainder(dividingBy: 30)
        var deg = Int(inSign)
        var min = Int(((inSign - Double(deg)) * 60).rounded())
        if min == 60 { min = 0; deg += 1 }
        return String(format: "%d°%02d′", deg, min)
    }
}
