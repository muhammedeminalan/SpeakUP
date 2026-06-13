import Foundation

struct GetSentencesUseCase {
    // Cümleleri karıştır — her seferinde farklı sıra
    func callAsFunction(_ sentences: [Sentence]) -> [Sentence] {
        sentences.shuffled()
    }

    // neden direction: TR→EN'de İngilizce kelimeleri, EN→TR'de Türkçe kelimeleri karıştırır
    func shuffledWords(for sentence: Sentence, direction: QuizDirection) -> [String] {
        let text = direction == .trToEn ? sentence.english : sentence.turkish
        // Noktalama kaldır, boş token filtrele, karıştır
        return text
            .replacingOccurrences(of: "[.,!?]", with: "", options: .regularExpression)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
            .shuffled()
    }
}
