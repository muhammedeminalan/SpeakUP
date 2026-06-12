import Foundation

extension String {
    /// İlk harfi ve `/` ayracından sonraki ilk harfi büyütür.
    /// Örnek: "topic/ subject" → "Topic/ Subject"
    /// neden regex: split/join yerine regex, boşluk farkını (/ vs / ) doğru yakalar
    func capitalizingSegments() -> String {
        guard !isEmpty else { return self }
        let first = prefix(1).uppercased() + dropFirst()
        guard let regex = try? NSRegularExpression(pattern: "(/\\s*)([a-zA-Z])") else {
            return first
        }

        var result = first
        // neden tersten: replace edildikçe index'ler kaymasın
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
        for match in matches.reversed() {
            guard let letterRange = Range(match.range(at: 2), in: result) else { continue }
            result.replaceSubrange(letterRange, with: result[letterRange].uppercased())
        }
        return result
    }
}
