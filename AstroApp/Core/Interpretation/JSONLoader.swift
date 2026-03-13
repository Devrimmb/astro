import Foundation

struct JSONLoader: Sendable {
    static func load<T: Decodable>(_ filename: String) -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            fatalError("JSON dosyası bulunamadı: \(filename).json")
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            fatalError("JSON dosyası okunamadı: \(filename).json — \(error)")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            fatalError("JSON decode hatası: \(filename).json — \(error)")
        }
    }
}
