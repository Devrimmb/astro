import Foundation

struct DailyHoroscope: Sendable {
    let sign: ZodiacSign
    let date: Date
    let generalText: String
    let advice: String
    let overallRating: Int
    let loveRating: Int
    let careerRating: Int
    let healthRating: Int
    let luckRating: Int
    let luckyColor: String
    let luckyNumber: Int

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}
