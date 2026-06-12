import Foundation

/// Quiz sorularını seçer ve 4'lü şık üretir
struct GetWordsForQuizUseCase {
    // Kelimeleri karıştırır ve soru sayısına göre kırpar
    //
    // neden weighted: kullanıcı yanlış yaptığı kelimeleri daha sık görsün
    func callAsFunction(_ words: [Word], count: Int, wrongCounts: [Int: Int] = [:]) -> [Word] {
        let targetCount = count == -1 ? words.count : min(max(count, 1), words.count)
        var pool = words

        if targetCount >= pool.count {
            return pool.shuffled()
        }

        var selected: [Word] = []
        while selected.count < targetCount, !pool.isEmpty {
            let pickedIndex = pickWeightedIndex(pool: pool, wrongCounts: wrongCounts)
            selected.append(pool.remove(at: pickedIndex))
        }
        return selected
    }

    private func pickWeightedIndex(pool: [Word], wrongCounts: [Int: Int]) -> Int {
        // Her kelimenin ağırlığı: 1 + yanlış sayısı
        let weights = pool.map { 1 + (wrongCounts[$0.id] ?? 0) }
        let totalWeight = weights.reduce(0, +)

        var roll = Int.random(in: 0..<totalWeight)
        for (index, weight) in weights.enumerated() {
            roll -= weight
            if roll < 0 { return index }
        }
        return weights.count - 1
    }

    // neden direction parametresi: TR→EN'de şıklar İngilizce, EN→TR'de Türkçe olmalı
    func generateOptions(for correct: Word, from allWords: [Word], direction: QuizDirection) -> [String] {
        let isEnAnswer = direction == .trToEn
        let correctOption = isEnAnswer ? correct.english : correct.turkish

        // neden Set→Array: aynı çeviriye sahip kelimeler şıklarda tekrar etmesin
        var others = Array(Set(
            allWords
                .filter { $0.id != correct.id }
                .map { isEnAnswer ? $0.english : $0.turkish }
        ))
        others.removeAll { $0 == correctOption }
        others.shuffle()

        return ([correctOption] + others.prefix(3)).shuffled()
    }
}
