import Foundation

/// Void of Course Moon (Ay Boslukta) donemi
struct VoidOfCourseMoon: Identifiable, Sendable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let fromSign: ZodiacSign
    let toSign: ZodiacSign

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationText: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)s \(minutes)dk"
        }
        return "\(minutes)dk"
    }

    var startText: String {
        formatDate(startDate)
    }

    var endText: String {
        formatDate(endDate)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM HH:mm"
        return formatter.string(from: date)
    }

    /// Su an VOC mu?
    var isActive: Bool {
        let now = Date.now
        return now >= startDate && now <= endDate
    }
}
