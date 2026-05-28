import Foundation

@Observable
final class GamificationManager {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let totalStars = "gm_total_stars"
        static let currentStreak = "gm_current_streak"
        static let longestStreak = "gm_longest_streak"
        static let lastCheckInDate = "gm_last_checkin_date"
        static let todayEarnedActions = "gm_today_earned_actions"
        static let todayEarnedDate = "gm_today_earned_date"
    }

    // MARK: - Published State

    var totalStars: Int {
        didSet { UserDefaults.standard.set(totalStars, forKey: Keys.totalStars) }
    }

    var currentStreak: Int {
        didSet { UserDefaults.standard.set(currentStreak, forKey: Keys.currentStreak) }
    }

    var longestStreak: Int {
        didSet { UserDefaults.standard.set(longestStreak, forKey: Keys.longestStreak) }
    }

    private(set) var lastCheckInDate: Date? {
        didSet {
            if let date = lastCheckInDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Keys.lastCheckInDate)
            }
        }
    }

    /// Bugün kazanılan aksiyonlar (tekrar kazanmayı önlemek için)
    private var todayEarnedActions: Set<String> {
        didSet { persistTodayActions() }
    }

    // MARK: - Seviye Sistemi

    struct CosmicLevel: Sendable {
        let rank: Int
        let name: String
        let icon: String
        let requiredStars: Int
    }

    static let levels: [CosmicLevel] = [
        CosmicLevel(rank: 1, name: "Yeni Ay", icon: "moonphase.new.moon", requiredStars: 0),
        CosmicLevel(rank: 2, name: "Hilal", icon: "moonphase.waxing.crescent", requiredStars: 100),
        CosmicLevel(rank: 3, name: "İlk Dördün", icon: "moonphase.first.quarter", requiredStars: 300),
        CosmicLevel(rank: 4, name: "Şişkin Ay", icon: "moonphase.waxing.gibbous", requiredStars: 600),
        CosmicLevel(rank: 5, name: "Dolunay", icon: "moonphase.full.moon", requiredStars: 1000),
        CosmicLevel(rank: 6, name: "Yıldız", icon: "star.fill", requiredStars: 1500),
        CosmicLevel(rank: 7, name: "Takımyıldız", icon: "sparkles", requiredStars: 2500),
        CosmicLevel(rank: 8, name: "Galaksi", icon: "hurricane", requiredStars: 4000),
        CosmicLevel(rank: 9, name: "Süpernova", icon: "sun.max.fill", requiredStars: 6000),
        CosmicLevel(rank: 10, name: "Evren", icon: "globe.americas.fill", requiredStars: 10000),
    ]

    var currentLevel: CosmicLevel {
        Self.levels.last(where: { $0.requiredStars <= totalStars }) ?? Self.levels[0]
    }

    var nextLevel: CosmicLevel? {
        Self.levels.first(where: { $0.requiredStars > totalStars })
    }

    /// Sonraki seviyeye ilerleme oranı (0.0 - 1.0)
    var levelProgress: Double {
        guard let next = nextLevel else { return 1.0 }
        let current = currentLevel.requiredStars
        let range = next.requiredStars - current
        guard range > 0 else { return 1.0 }
        return Double(totalStars - current) / Double(range)
    }

    // MARK: - Ödül Tanımları

    enum StarAction: String {
        case dailyCheckIn = "daily_checkin"
        case viewDailyHoroscope = "view_daily_horoscope"
        case cardReading = "card_reading"
        case checkMoonPhase = "check_moon_phase"
        case shareResult = "share_result"
        case watchAd = "watch_ad"

        var stars: Int {
            switch self {
            case .dailyCheckIn: 10
            case .viewDailyHoroscope: 10
            case .cardReading: 15
            case .checkMoonPhase: 5
            case .shareResult: 20
            case .watchAd: 25
            }
        }

        var displayName: String {
            switch self {
            case .dailyCheckIn: "Günlük Giriş"
            case .viewDailyHoroscope: "Günlük Burç Oku"
            case .cardReading: "Kart Falı Bak"
            case .checkMoonPhase: "Ay Fazını Kontrol Et"
            case .shareResult: "Sonuç Paylaş"
            case .watchAd: "Reklam İzle"
            }
        }

        var icon: String {
            switch self {
            case .dailyCheckIn: "flame.fill"
            case .viewDailyHoroscope: "sun.horizon.fill"
            case .cardReading: "sparkles"
            case .checkMoonPhase: "moon.stars.fill"
            case .shareResult: "square.and.arrow.up"
            case .watchAd: "play.rectangle.fill"
            }
        }

        /// Bu aksiyon günde bir kez mi kazanılır?
        var isOncePerDay: Bool {
            switch self {
            case .dailyCheckIn, .viewDailyHoroscope, .checkMoonPhase: true
            case .cardReading, .shareResult, .watchAd: false
            }
        }
    }

    // MARK: - Streak Bonus

    /// Streak'e göre bonus çarpan
    var streakMultiplier: Double {
        switch currentStreak {
        case 0...2: 1.0
        case 3...6: 1.2    // 3+ gün: %20 bonus
        case 7...13: 1.5   // 1 hafta: %50 bonus
        case 14...29: 1.8  // 2 hafta: %80 bonus
        default: 2.0       // 30+ gün: %100 bonus
        }
    }

    var streakBonusText: String? {
        guard streakMultiplier > 1.0 else { return nil }
        let percent = Int((streakMultiplier - 1.0) * 100)
        return "+%\(percent) bonus"
    }

    // MARK: - Init

    init() {
        totalStars = UserDefaults.standard.integer(forKey: Keys.totalStars)
        currentStreak = UserDefaults.standard.integer(forKey: Keys.currentStreak)
        longestStreak = UserDefaults.standard.integer(forKey: Keys.longestStreak)

        let ts = UserDefaults.standard.double(forKey: Keys.lastCheckInDate)
        lastCheckInDate = ts > 0 ? Date(timeIntervalSince1970: ts) : nil

        // Bugünün aksiyonlarını yükle
        let savedDate = UserDefaults.standard.string(forKey: Keys.todayEarnedDate) ?? ""
        if savedDate == Self.todayKey {
            let saved = UserDefaults.standard.stringArray(forKey: Keys.todayEarnedActions) ?? []
            todayEarnedActions = Set(saved)
        } else {
            todayEarnedActions = []
        }

        // Streak kontrolü: dün giriş yapılmadıysa streak sıfırla
        validateStreak()
    }

    // MARK: - Günlük Check-in

    /// Uygulamayı açtığında çağrılır. Günde bir kez streak'i günceller.
    @discardableResult
    func dailyCheckIn() -> Int {
        guard !hasCheckedInToday else { return 0 }
        return earn(.dailyCheckIn)
    }

    var hasCheckedInToday: Bool {
        guard let last = lastCheckInDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: - Yıldız Kazan

    /// Bir aksiyon için yıldız kazan. Günde bir kez kazanılan aksiyonlar tekrar kazanılamaz.
    @discardableResult
    func earn(_ action: StarAction) -> Int {
        // Günlük aksiyonlar için kontrol
        if action.isOncePerDay && todayEarnedActions.contains(action.rawValue) {
            return 0
        }

        let baseStars = action.stars
        let bonus = Int(Double(baseStars) * (streakMultiplier - 1.0))
        let totalEarned = baseStars + bonus

        totalStars += totalEarned

        // Günlük aksiyonu kaydet
        if action.isOncePerDay {
            todayEarnedActions.insert(action.rawValue)
        }

        // Görev tamamlama marker'ları
        if action == .cardReading {
            todayEarnedActions.insert("card_reading_done")
        } else if action == .shareResult {
            todayEarnedActions.insert("share_done")
        }

        // Check-in ise streak güncelle
        if action == .dailyCheckIn {
            updateStreak()
        }

        // En uzun streak güncelle
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        return totalEarned
    }

    /// Yıldız harca (reklam yerine fal açma vb.)
    func spend(_ amount: Int) -> Bool {
        guard totalStars >= amount else { return false }
        totalStars -= amount
        return true
    }

    /// Belirli bir aksiyonun bugün kazanılıp kazanılmadığını kontrol et
    func hasEarnedToday(_ action: StarAction) -> Bool {
        action.isOncePerDay && todayEarnedActions.contains(action.rawValue)
    }

    // MARK: - Streak Yönetimi

    private func updateStreak() {
        if let last = lastCheckInDate {
            if Calendar.current.isDateInYesterday(last) {
                // Dün giriş yapmış → streak devam
                currentStreak += 1
            } else if !Calendar.current.isDateInToday(last) {
                // Dünden daha eski → streak kırıldı
                currentStreak = 1
            }
            // Bugün zaten giriş yapılmış → değiştirme
        } else {
            // İlk giriş
            currentStreak = 1
        }

        lastCheckInDate = Date.now
    }

    private func validateStreak() {
        guard let last = lastCheckInDate else { return }
        // Son giriş bugün veya dün değilse, streak kırıldı
        if !Calendar.current.isDateInToday(last) && !Calendar.current.isDateInYesterday(last) {
            currentStreak = 0
        }
    }

    // MARK: - Persistence Helpers

    private static var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }

    private func persistTodayActions() {
        UserDefaults.standard.set(Array(todayEarnedActions), forKey: Keys.todayEarnedActions)
        UserDefaults.standard.set(Self.todayKey, forKey: Keys.todayEarnedDate)
    }

    // MARK: - Günlük Görevler

    struct DailyTask: Identifiable {
        let id: String
        let title: String
        let icon: String
        let stars: Int
        let isCompleted: Bool
    }

    /// Bugünün görev listesini döndür
    var dailyTasks: [DailyTask] {
        [
            DailyTask(
                id: StarAction.dailyCheckIn.rawValue,
                title: "Uygulamayı Aç",
                icon: StarAction.dailyCheckIn.icon,
                stars: StarAction.dailyCheckIn.stars,
                isCompleted: hasEarnedToday(.dailyCheckIn)
            ),
            DailyTask(
                id: StarAction.viewDailyHoroscope.rawValue,
                title: "Günlük Burcunu Oku",
                icon: StarAction.viewDailyHoroscope.icon,
                stars: StarAction.viewDailyHoroscope.stars,
                isCompleted: hasEarnedToday(.viewDailyHoroscope)
            ),
            DailyTask(
                id: StarAction.checkMoonPhase.rawValue,
                title: "Ay Fazını Kontrol Et",
                icon: StarAction.checkMoonPhase.icon,
                stars: StarAction.checkMoonPhase.stars,
                isCompleted: hasEarnedToday(.checkMoonPhase)
            ),
            DailyTask(
                id: "card_reading_daily",
                title: "Bir Fal Bak",
                icon: StarAction.cardReading.icon,
                stars: StarAction.cardReading.stars,
                isCompleted: todayEarnedActions.contains("card_reading_done")
            ),
            DailyTask(
                id: "share_daily",
                title: "Bir Sonuç Paylaş",
                icon: StarAction.shareResult.icon,
                stars: StarAction.shareResult.stars,
                isCompleted: todayEarnedActions.contains("share_done")
            ),
        ]
    }

    var completedTaskCount: Int {
        dailyTasks.filter(\.isCompleted).count
    }

    var totalTaskCount: Int {
        dailyTasks.count
    }

    /// Kart falı baktığında günlük görevi de tamamla
    func markCardReadingDone() {
        todayEarnedActions.insert("card_reading_done")
    }

    /// Paylaşım yaptığında günlük görevi de tamamla
    func markShareDone() {
        todayEarnedActions.insert("share_done")
    }
}
