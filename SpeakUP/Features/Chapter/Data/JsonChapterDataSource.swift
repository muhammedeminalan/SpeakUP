import Foundation

/// Bundle içindeki bölüm JSON'larını okuyup domain entity'lere çevirir.
/// neden Codable yerine elle parse: JSON key'ler Türkçe karakterli
/// (türkçe/ingilizce/devrik) — CodingKeys ile de yapılabilirdi ama
/// Flutter tarafıyla aynı hata mesajları ve davranış korunmak istendi.
struct JsonChapterDataSource {
    // Bundle'daki JSON dosyaları — ileride uzak kaynak ile değiştirilecek
    private static let assetNames = [
        "bolum-1", "bolum-2", "bolum-3", "bolum-4", "bolum-5", "bolum-6",
    ]

    func getChapters() throws -> [Chapter] {
        try Self.assetNames.map { name in
            guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
                throw AppFailure.data("Bölüm dosyası bulunamadı: \(name).json")
            }
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw AppFailure.data("Geçersiz JSON formatı: \(name).json")
            }
            return try parseChapter(id: name, json: json)
        }
    }

    private func parseChapter(id: String, json: [String: Any]) throws -> Chapter {
        guard let wordList = json["kelimeler"] as? [[String: Any]],
              let sentenceList = json["cümleler"] as? [[String: Any]] else {
            throw AppFailure.data("Bölüm içeriği eksik: \(id)")
        }

        let words = try wordList.map { try parseWord($0, chapterId: id) }
        let sentences = try sentenceList.map(parseSentence)

        return Chapter(id: id, name: Self.buildName(id: id), words: words, sentences: sentences)
    }

    private func parseWord(_ json: [String: Any], chapterId: String) throws -> Word {
        guard let id = json["id"] as? Int,
              let turkish = json["türkçe"] as? String,
              let english = json["ingilizce"] as? String else {
            throw AppFailure.data("Kelime kaydı eksik alan içeriyor (bölüm: \(chapterId))")
        }
        return Word(id: id, chapterId: chapterId, turkish: turkish, english: english)
    }

    private func parseSentence(_ json: [String: Any]) throws -> Sentence {
        guard let id = json["id"] as? Int,
              let turkish = json["türkçe"] as? String,
              let restructured = json["devrik"] as? String,
              let english = json["ingilizce"] as? String else {
            throw AppFailure.data("Cümle kaydı eksik alan içeriyor")
        }
        return Sentence(id: id, turkish: turkish, turkishRestructured: restructured, english: english)
    }

    // "bolum-1" → "Bölüm 1"
    private static func buildName(id: String) -> String {
        let parts = id.split(separator: "-")
        return parts.count == 2 ? "Bölüm \(parts[1])" : id
    }
}
